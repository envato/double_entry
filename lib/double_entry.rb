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

    # Get an Account::Instance for a particular account.
    #
    # For example, the following will return the cash account for a user:
    #
    #     DoubleEntry.account(:cash, :scope => user)
    #
    def account(identifier, args = {})
      match = @accounts.detect do |a|
        a.identifier == identifier and (args[:scope] ? a.scoped? : !a.scoped?)
      end

      if match
        DoubleEntry::Account::Instance.new(:account => match, :scope => args[:scope])
      else
        raise UnknownAccount.new("account: #{identifier} scope: #{args[:scope]}")
      end
    end

    # Transfer money from one account to another.
    #
    # For example, the following will transfer $20 from a user's checking
    # account to their savings account:
    #
    #     checking_account = DoubleEntry.account(:checking, :scope => user)
    #     savings_account  = DoubleEntry.account(:savings,  :scope => user)
    #     DoubleEntry.transfer(
    #       Money.new(20_00),
    #       :from => checking_account,
    #       :to   => savings_account,
    #       :code => :save,
    #     )
    #
    # Only certain transfers are allowed. Define which are allowed in your
    # configuration file.
    #
    # The :detail option lets you pass in an arbitrary ActiveRecord object that
    # will be stored (via a polymorphic association) with the lines table
    # entries for the transfer.
    #
    # The :meta option lets you pass in metadata (as a string) that you want
    # stored with the transaction.
    #
    # If you're doing more than one transfer in one hit, or you're doing other
    # database operations along with your transfer, you'll need to use the
    # lock_accounts method.
    def transfer(amount, args = {})
      raise TransferIsNegative if amount < Money.new(0)

      from, to, code, meta, detail = args[:from], args[:to], args[:code], args[:meta], args[:detail]

      transfer = @transfers.find(from, to, code)

      if transfer
        transfer.process!(amount, from, to, code, meta, detail)
      else
        raise TransferNotAllowed.new([from.identifier, to.identifier, code].inspect)
      end
    end

    # Get the current balance of an account, as a Money object.
    def balance(account, args = {})
      scope_arg = args[:scope] ? args[:scope].id.to_s : nil
      scope = (account.is_a?(Symbol) ? scope_arg : account.scope_identity)
      account = (account.is_a?(Symbol) ? account : account.identifier).to_s
      from, to, at = args[:from], args[:to], args[:at]
      code, codes = args[:code], args[:codes]

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
    def scopes_with_minimum_balance_for_account(minimum_balance, account_identifier)
      select_values(sanitize_sql_array([<<-SQL, account_identifier, minimum_balance.cents])).map {|scope| scope.to_i }
        SELECT scope
          FROM #{AccountBalance.quoted_table_name}
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
    # The transaction must be the outermost database transaction, or this will
    # raise an DoubleEntry::Locking::LockMustBeOutermostTransaction exception.
    def lock_accounts(*accounts, &block)
      DoubleEntry::Locking.lock_accounts(*accounts, &block)
    end

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

    # Returns true if all the amounts for an account add up to the final balance,
    # which they always should.
    #
    # This is used by the concurrency test script.
    def reconciled?(account)
      scoped_lines = Line.where(:account => "#{account.identifier}", :scope => "#{account.scope}")
      sum_of_amounts = scoped_lines.sum(:amount)
      final_balance  = scoped_lines.order(:id).last[:balance]
      cached_balance = AccountBalance.find_by_account(account)[:balance]
      final_balance == sum_of_amounts && final_balance == cached_balance
    end

    def table_name_prefix
      'double_entry_'
    end

  private

    delegate :connection, :to => ActiveRecord::Base
    delegate :select_values, :to => :connection

    def sanitize_sql_array(sql_array)
      ActiveRecord::Base.send(:sanitize_sql_array, sql_array)
    end

  end

end
