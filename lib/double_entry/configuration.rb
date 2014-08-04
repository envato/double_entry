# encoding: utf-8
module DoubleEntry
  include Configurable

  class Configuration
    attr_accessor :accounts, :transfers

    def initialize #:nodoc:
      @accounts = Account::Set.new
      @transfers = Transfer::Set.new
    end

    def define_accounts
      yield accounts
    end

    def define_transfers
      yield transfers
    end

    def default_currency
      @default_currency || Money.default_currency
    end

    def set_default_currency
      @default_currency = yield
    end
  end
end
