# encoding: utf-8
require 'active_record'
require 'active_record/locking_extensions'
require 'active_support/all'
require 'money'
require 'encapsulate_as_money'

require 'double_entry/version'
require 'double_entry/errors'
require 'double_entry/configurable'
require 'double_entry/configuration'
require 'double_entry/account'
require 'double_entry/account_balance'
require 'double_entry/balance_calculator'
require 'double_entry/balance_transferrer'
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
      BalanceTransferrer.new(configuration.transfers).transfer(amount, options)
    end

    # Get the current or historic balance of an account.
    #
    # @param account [DoubleEntry::Account:Instance, Symbol]
    # @option options :scope [Object, String]
    # @option options :from [Time]
    # @option options :to [Time]
    # @option options :at [Time]
    # @option options :code [Symbol]
    # @option options :codes [Array<Symbol>]
    # @return [Money]
    def balance(account, options = {})
      BalanceCalculator.calculate(account, options)
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
      DoubleEntry::Locking.lock_accounts(*accounts, &block)
    end

    # @api private
    def describe(line)
      # make sure we have a test for this refactoring, the test
      # conditions are: i forget... but it's important!
      if line.credit?
        configuration.transfers.find(line.account, line.partner_account, line.code)
      else
        configuration.transfers.find(line.partner_account, line.account, line.code)
      end.description.call(line)
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
