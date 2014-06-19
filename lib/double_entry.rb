# encoding: utf-8
require 'active_record'
require 'money'

# Include active record extensions
require 'active_record/locking_extensions'

require 'encapsulate_as_money'

require 'double_entry/version'

require 'double_entry/configurable'

require 'double_entry/account'
require 'double_entry/account_balance'

require 'double_entry/aggregate'
require 'double_entry/aggregate_array'

require 'double_entry/time_range'
require 'double_entry/time_range_array'

require 'double_entry/day_range'
require 'double_entry/hour_range'
require 'double_entry/week_range'
require 'double_entry/month_range'
require 'double_entry/year_range'

require 'double_entry/line'
require 'double_entry/line_aggregate'
require 'double_entry/line_check'

require 'double_entry/locking'

require 'double_entry/transfer'

# Keep track of all the monies!
#
# This module provides the public interfaces for everything to do with
# transferring money around the system.
module DoubleEntry

  class UnknownAccount < RuntimeError; end
  class TransferNotAllowed < RuntimeError; end
  class TransferIsNegative < RuntimeError; end
  class RequiredMetaMissing < RuntimeError; end
  class DuplicateAccount < RuntimeError; end
  class DuplicateTransfer < RuntimeError; end
  class UserAccountNotLocked < RuntimeError; end
  class AccountWouldBeSentNegative < RuntimeError; end

  class << self
    attr_accessor :accounts, :transfers

    # Get the particular account instance with the provided identifier and
    # scope.
    #
    # @example Obtain the 'cash' account for a user
    #   DoubleEntry.account(:cash, scope: user)
    # @param identifier [Symbol] The code identifying the desired account. As
    #   specified in the account configuration.
    # @option options :scope Limit the account to the given scope. As specified
    #   in the account configuration.
    # @return [DoubleEntry::Account::Instance]
    # @raise [DoubleEntry::UnknownAccount] The described account has not been
    #   configured. It is unknown.
    #
    def account(identifier, options = {})
      account = @accounts.detect do |current_account|
        current_account.identifier == identifier and
          (options[:scope] ? current_account.scoped? : !current_account.scoped?)
      end

      if account
        DoubleEntry::Account::Instance.new(:account => account, :scope => options[:scope])
      else
        raise UnknownAccount.new("account: #{identifier} scope: #{options[:scope]}")
      end
    end

    # Transfer money from one account to another.
    #
    # Only certain transfers are allowed. Define legal transfers in your
    # configuration file.
    #
    # If you're doing more than one transfer in one hit, or you're doing other
    # database operations along with your transfer, you'll need to use the
    # lock_accounts method.
    #
    # @example Transfer $20 from a user's checking to savings account
    #   checking_account = DoubleEntry.account(:checking, scope: user)
    #   savings_account  = DoubleEntry.account(:savings,  scope: user)
    #   DoubleEntry.transfer(
    #     Money.new(20_00),
    #     from: checking_account,
    #     to:   savings_account,
    #     code: :save,
    #   )
    #
    # @param amount [Money] The quantity of money to transfer from one account
    #   to the other.
    # @option options :from [DoubleEntry::Account::Instance] Transfer money out
    #   of this account.
    # @option options :to [DoubleEntry::Account::Instance] Transfer money into
    #   this account.
    # @option options :code [Symbol] Your application specific code for this
    #   type of transfer.
    # @option options :meta [String] Metadata to associate with this transfer.
    # @option options :detail [ActiveRecord::Base] ActiveRecord model
    #   associated (via a polymorphic association) with the transfer.
    # @raise [DoubleEntry::TransferIsNegative] The amount is less than zero.
    # @raise [DoubleEntry::TransferNotAllowed] A transfer between these
    #   accounts with the provided code is not allowed. Check configuration.
    #
    def transfer(amount, options = {})
      raise TransferIsNegative if amount < Money.new(0)
      from, to, code, meta, detail = options[:from], options[:to], options[:code], options[:meta], options[:detail]
      transfer = @transfers.find(from, to, code)
      if transfer
        transfer.process!(amount, from, to, code, meta, detail)
      else
        raise TransferNotAllowed.new([from.identifier, to.identifier, code].inspect)
      end
    end

    # Get the current balance of an account, as a Money object.
    #
    # @param account [DoubleEntry::Account:Instance, Symbol]
    # @option options :scope [Symbol]
    # @option options :from [Time]
    # @option options :to [Time]
    # @option options :at [Time]
    # @option options :code [Symbol]
    # @option options :codes [Array<Symbol>]
    # @return [Money]
    def balance(account, options = {})
      scope_arg = options[:scope] ? options[:scope].id.to_s : nil
      scope = (account.is_a?(Symbol) ? scope_arg : account.scope_identity)
      account = (account.is_a?(Symbol) ? account : account.identifier).to_s
      from, to, at = options[:from], options[:to], options[:at]
      code, codes = options[:code], options[:codes]

      # time based scoping
      conditions = if at
        # lookup method could use running balance, with a order by limit one clause
        # (unless it's a reporting call, i.e. account == symbol and not an instance)
        ['account = ? and created_at <= ?', account, at] # index this??
      elsif from and to
        ['account = ? and created_at >= ? and created_at <= ?', account, from, to] # index this??
      else
        # lookup method could use running balance, with a order by limit one clause
        # (unless it's a reporting call, i.e. account == symbol and not an instance)
        ['account = ?', account]
      end

      # code based scoping
      if code
        conditions[0] << ' and code = ?' # index this??
        conditions << code.to_s
      elsif codes
        conditions[0] << ' and code in (?)' # index this??
        conditions << codes.collect { |c| c.to_s }
      end

      # account based scoping
      if scope
        conditions[0] << ' and scope = ?'
        conditions << scope

        # This is to work around a MySQL 5.1 query optimiser bug that causes the ORDER BY
        # on the query to fail in some circumstances, resulting in an old balance being
        # returned. This was biting us intermittently in spec runs.
        # See http://bugs.mysql.com/bug.php?id=51431
        if Line.connection.adapter_name.match /mysql/i
          use_index = "USE INDEX (lines_scope_account_id_idx)"
        end
      end

      if (from and to) or (code or codes)
        # from and to or code lookups have to be done via sum
        Money.new(Line.where(conditions).sum(:amount))
      else
        # all other lookups can be performed with running balances
        line = Line.select("id, balance").from("#{Line.quoted_table_name} #{use_index}").where(conditions).order('id desc').first
        line ? line.balance : Money.empty
      end
    end

    # Identify the scopes with the given account identifier holding at least
    # the provided minimum balance.
    #
    # @param minimum_balance [Money] Minimum account balance to be included in
    #   the result set.
    # @param account_identifier [Symbol]
    # @return [Array<Fixnum>] Scopes
    def scopes_with_minimum_balance_for_account(minimum_balance, account_identifier)
      select_values(sanitize_sql_array([<<-SQL, account_identifier, minimum_balance.cents])).map {|scope| scope.to_i }
        SELECT scope
          FROM account_balances
         WHERE account = ?
           AND balance >= ?
      SQL
    end

    # Lock accounts in preparation for transfers.
    #
    # This creates a transaction, and uses database-level locking to ensure
    # that we're the only ones who can transfer to or from the given accounts
    # for the duration of the transaction.
    #
    # @example Lock the savings and checking account for a user
    #   checking_account = DoubleEntry.account(:checking, scope: user)
    #   savings_account  = DoubleEntry.account(:savings,  scope: user)
    #   DoubleEntry.lock_accounts(checking_account, savings_account) do
    #     # ...
    #   end
    # @yield Hold the locks while the provided block is processed.
    # @raise [DoubleEntry::Locking::LockMustBeOutermostTransaction]
    #   The transaction must be the outermost database transaction
    #
    def lock_accounts(*accounts, &block)
      DoubleEntry::Locking.lock_accounts(*accounts, &block)
    end

    # @api private
    def describe(line)
      # make sure we have a test for this refactoring, the test
      # conditions are: i forget... but it's important!
      if line.credit?
        @transfers.find(line.account, line.partner_account, line.code)
      else
        @transfers.find(line.partner_account, line.account, line.code)
      end.description.call(line)
    end

    def aggregate(function, account, code, options = {})
      DoubleEntry::Aggregate.new(function, account, code, options).formatted_amount
    end

    def aggregate_array(function, account, code, options = {})
      DoubleEntry::AggregateArray.new(function, account, code, options)
    end

    # This is used by the concurrency test script.
    #
    # @api private
    # @return [Boolean] true if all the amounts for an account add up to the final balance,
    #   which they always should.
    def reconciled?(account)
      scoped_lines = Line.where(:account => "#{account.identifier}", :scope => "#{account.scope}")
      sum_of_amounts = scoped_lines.sum(:amount)
      final_balance  = scoped_lines.order(:id).last[:balance]
      cached_balance = AccountBalance.find_by_account(account)[:balance]
      final_balance == sum_of_amounts && final_balance == cached_balance
    end

  private

    delegate :connection, :to => ActiveRecord::Base
    delegate :select_values, :to => :connection

    def sanitize_sql_array(sql_array)
      ActiveRecord::Base.send(:sanitize_sql_array, sql_array)
    end

  end

end
