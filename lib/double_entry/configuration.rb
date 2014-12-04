# encoding: utf-8
module DoubleEntry
  include Configurable

  class Configuration
    delegate :accounts, :accounts=, :to => "DoubleEntry::Account"
    delegate :transfers, :transfers=, :to => "DoubleEntry::Transfer"

    def define_accounts
      yield accounts
    end

    def define_transfers
      yield transfers
    end
  end
end
