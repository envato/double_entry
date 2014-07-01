# encoding: utf-8
require 'active_record'
require 'active_record/locking_extensions'
require 'active_support/all'
require 'money'
require 'encapsulate_as_money'

require 'double_entry/version'
require 'double_entry/configurable'
require 'double_entry/configuration'
require 'double_entry/account'
require 'double_entry/account_balance'
require 'double_entry/locking'
require 'double_entry/transfer'
require 'double_entry/line'
require 'double_entry/reporting'
require 'double_entry/validation'

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

    # Get the particular account instance with the provided identifier and
    # scope.
    #
    # @example Obtain the 'cash' account for a user
    #   DoubleEntry.account(:cash, scope: user)
    # @param identifier [Symbol] The symbol identifying the desired account. As
    #   specified in the account configuration.
    # @option options :scope Limit the account to the given scope. As specified
    #   in the account configuration.
    # @return [DoubleEntry::Account::Instance]
    # @raise [DoubleEntry::UnknownAccount] The described account has not been
    #   configured. It is unknown.
    #
    def account(identifier, options = {})
      account = configuration.accounts.detect do |current_account|
        current_account.identifier == identifier &&
          (options[:scope] ? current_account.scoped? : !current_account.scoped?)
      end

      if account
        Account::Instance.new(:account => account, :scope => options[:scope])
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
    # @param amount [Money] The quantity of money to transfer from one account
    #   to the other.
    # @option options :from [DoubleEntry::Account::Instance] Transfer money out
    #   of this account.
    # @option options :to [DoubleEntry::Account::Instance] Transfer money into
    #   this account.
    # @option options :code [Symbol] Your application specific code for this
    #   type of transfer. As specified in the transfer configuration.
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
      transfer = configuration.transfers.find(from, to, code)
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

    # Lock accounts in preparation for transfers.
    #
    # This creates a transaction, and uses database-level locking to ensure
    # that we're the only ones who can transfer to or from the given accounts
    # for the duration of the transaction.
    #
    # @example Lock the savings and checking accounts for a user
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
      Locking.lock_accounts(*accounts, &block)
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

    def table_name_prefix
      'double_entry_'
    end
  end
end
