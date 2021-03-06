# encoding: utf-8
require 'active_record'
require 'active_record/locking_extensions'
require 'active_record/locking_extensions/log_subscriber'
require 'active_support/all'
require 'money'
require 'rails/railtie'

require 'double_entry/version'
require 'double_entry/errors'
require 'double_entry/configurable'
require 'double_entry/configuration'
require 'double_entry/account'
require 'double_entry/account_balance'
require 'double_entry/balance_calculator'
require 'double_entry/locking'
require 'double_entry/transfer'
require 'double_entry/validation'

# Keep track of all the monies!
#
# This module provides the public interfaces for everything to do with
# transferring money around the system.
module DoubleEntry
  class Railtie < ::Rails::Railtie
    # So we can access user config from initializer in their app
    config.after_initialize do
      unless DoubleEntry.config.json_metadata
        require 'double_entry/line_metadata'
      end
      require 'double_entry/line'
    end
  end

  class << self
    # Get the particular account instance with the provided identifier and
    # scope.
    #
    # @example Obtain the 'cash' account for a user
    #   DoubleEntry.account(:cash, scope: user)
    # @param [Symbol] identifier The symbol identifying the desired account. As
    #   specified in the account configuration.
    # @option options :scope Limit the account to the given scope. As specified
    #   in the account configuration.
    # @return [DoubleEntry::Account::Instance]
    # @raise [DoubleEntry::UnknownAccount] The described account has not been
    #   configured. It is unknown.
    # @raise [DoubleEntry::AccountScopeMismatchError] The provided scope does not
    #   match that defined on the account.
    #
    def account(identifier, options = {})
      Account.account(identifier, options)
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
    #   credit, debit = DoubleEntry.transfer(
    #     20.dollars,
    #     from: checking_account,
    #     to:   savings_account,
    #     code: :save,
    #   )
    # @param [Money] amount The quantity of money to transfer from one account
    #   to the other.
    # @option options :from [DoubleEntry::Account::Instance] Transfer money out
    #   of this account.
    # @option options :to [DoubleEntry::Account::Instance] Transfer money into
    #   this account.
    # @option options :code [Symbol] The application specific code for this
    #   type of transfer. As specified in the transfer configuration.
    # @option options :detail [ActiveRecord::Base] ActiveRecord model
    #   associated (via a polymorphic association) with the transfer.
    # @return [[Line, Line]] The credit & debit (in that order) created by the transfer
    # @raise [DoubleEntry::TransferIsNegative] The amount is less than zero.
    # @raise [DoubleEntry::TransferNotAllowed] A transfer between these
    #   accounts with the provided code is not allowed. Check configuration.
    #
    def transfer(amount, options = {})
      Transfer.transfer(amount, options)
    end

    # Get the current or historic balance of an account.
    #
    # @example Obtain the current balance of my checking account
    #   checking_account = DoubleEntry.account(:checking, scope: user)
    #   DoubleEntry.balance(checking_account)
    # @example Obtain the current balance of my checking account (without account or user model)
    #   DoubleEntry.balance(:checking, scope: user_id)
    # @example Obtain a historic balance of my checking account
    #   checking_account = DoubleEntry.account(:checking, scope: user)
    #   DoubleEntry.balance(checking_account, at: Time.new(2012, 1, 1))
    # @example Obtain the net balance of my checking account during may
    #   checking_account = DoubleEntry.account(:checking, scope: user)
    #   DoubleEntry.balance(
    #     checking_account,
    #     from: Time.new(2012, 5,  1,  0,  0,  0),
    #     to:   Time.new(2012, 5, 31, 23, 59, 59),
    #   )
    # @example Obtain the balance of salary deposits made to my checking account during may
    #   checking_account = DoubleEntry.account(:checking, scope: user)
    #   DoubleEntry.balance(
    #     checking_account,
    #     code: :salary,
    #     from: Time.new(2012, 5,  1,  0,  0,  0),
    #     to:   Time.new(2012, 5, 31, 23, 59, 59),
    #   )
    # @example Obtain the balance of salary & lottery deposits made to my checking account during may
    #   checking_account = DoubleEntry.account(:checking, scope: user)
    #   DoubleEntry.balance(
    #     checking_account,
    #     codes: [ :salary, :lottery ],
    #     from:  Time.new(2012, 5,  1,  0,  0,  0),
    #     to:    Time.new(2012, 5, 31, 23, 59, 59),
    #   )
    # @param [DoubleEntry::Account:Instance, Symbol] account Find the balance
    #   for this account
    # @option options :scope [Object] The scope identifier of the account (only
    #   needed if the provided account is a symbol).
    # @option options :from [Time] used with :to, consider only the time
    #   between these dates
    # @option options :to [Time] used with :from, consider only the time
    #   between these dates
    # @option options :at [Time] obtain the account balance at this time
    # @option options :code [Symbol] consider only the transfers with this code
    # @option options :codes [Array<Symbol>] consider only the transfers with
    #   these codes
    # @return [Money] The balance
    # @raise [DoubleEntry::UnknownAccount] The described account has not been
    #   configured. It is unknown.
    # @raise [DoubleEntry::AccountScopeMismatchError] The provided scope does not
    #   match that defined on the account.
    def balance(account, options = {})
      account = account(account, options) if account.is_a? Symbol
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
      Locking.lock_accounts(*accounts, &block)
    end

    # @api private
    def table_name_prefix
      'double_entry_'
    end
  end
end
