# encoding: utf-8
module DoubleEntry
  # Account balance records cache the current balance for each account. They
  # also provide a database representation of an account that we can use to do
  # DB level locking.
  #
  # See DoubleEntry::Locking for more info on locking.
  #
  # Account balances are created on demand when transfers occur.
  class AccountBalance < ActiveRecord::Base
    delegate :currency, to: :account

    def balance
      self[:balance] && Money.new(self[:balance], currency)
    end

    def balance=(money)
      self[:balance] = (money && money.fractional)
    end

    def account=(account)
      self[:account] = account.identifier.to_s
      self[:scope] = account.scope_identity
      account
    end

    def account
      DoubleEntry.account(self[:account].to_sym, scope_identity: self[:scope])
    end

    def self.find_by_account(account, options = {})
      scope = where(scope: account.scope_identity, account: account.identifier.to_s)
      scope = scope.lock(true) if options[:lock]
      scope.first
    end

    # Identify the scopes with the given account identifier holding at least
    # the provided minimum balance.
    #
    # @example Find users with at least $1,000,000 in their savings accounts
    #   DoubleEntry::AccountBalance.scopes_with_minimum_balance_for_account(
    #     1_000_000.dollars,
    #     :savings,
    #   ) # might return the user ids: [ '1423', '12232', '34729' ]
    # @param [Money] minimum_balance Minimum account balance a scope must have
    #   to be included in the result set.
    # @param [Symbol] account_identifier
    # @return [Array<String>] Scopes
    #
    def self.scopes_with_minimum_balance_for_account(minimum_balance, account_identifier)
      where(account: account_identifier).where('balance >= ?', minimum_balance.fractional).pluck(:scope)
    end
  end
end
