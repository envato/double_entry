# encoding: utf-8
module DoubleEntry
  include Configurable

  class Configuration
    attr_accessor :json_metadata
    attr_writer :money_adapter

    def initialize
      @json_metadata = false
    end

    def money_adapter
      @money_adapter ||= begin
        require 'money'
        ::Money
      end
    end

    delegate(
      :accounts,
      :accounts=,
      :scope_identifier_max_length,
      :scope_identifier_max_length=,
      :account_identifier_max_length,
      :account_identifier_max_length=,
      to: 'DoubleEntry::Account',
    )

    delegate(
      :transfers,
      :transfers=,
      :code_max_length,
      :code_max_length=,
      to: 'DoubleEntry::Transfer',
    )

    def define_accounts
      yield accounts
    end

    def define_transfers
      yield transfers
    end
  end
end
