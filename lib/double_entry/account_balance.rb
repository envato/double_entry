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
    extend EncapsulateAsMoney

    encapsulate_as_money :balance

    def account=(account)
      self[:account] = account.identifier.to_s
      self[:scope] = account.scope_identity
      account
    end

    def self.find_by_account(account, options = {})
      scope = where(:scope => account.scope_identity, :account => account.identifier.to_s)
      scope = scope.lock(true) if options[:lock]
      scope.first
    end

  end

end
