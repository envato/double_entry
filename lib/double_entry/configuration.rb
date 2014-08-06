# encoding: utf-8
module DoubleEntry
  include Configurable

  class Configuration
    attr_accessor :accounts, :transfers, :default_currency

    def initialize #:nodoc:
      @accounts = Account::Set.new
      @transfers = Transfer::Set.new
      @default_currency = Money.default_currency
    end

    def define_accounts
      yield accounts
    end

    def define_transfers
      yield transfers
    end

    def default_currency=(currency)
      @default_currency = Money::Currency.find(currency)
    end
  end
end
