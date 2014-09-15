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
  end
end
