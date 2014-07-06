# encoding: utf-8
require 'double_entry/reporting/aggregate'
require 'double_entry/reporting/aggregate_array'
require 'double_entry/reporting/time_range'
require 'double_entry/reporting/time_range_array'
require 'double_entry/reporting/day_range'
require 'double_entry/reporting/hour_range'
require 'double_entry/reporting/week_range'
require 'double_entry/reporting/month_range'
require 'double_entry/reporting/year_range'
require 'double_entry/reporting/line_aggregate'

module DoubleEntry

  # @api private
  module Reporting
    include Configurable
    extend self

    class Configuration
      attr_accessor :start_of_business, :first_month_of_financial_year

      def initialize #:nodoc:
        @start_of_business = Time.new(1970, 1, 1)
        @first_month_of_financial_year = 7
      end
    end

    class AggregateFunctionNotSupported < RuntimeError; end

    # Perform an aggregate calculation on a set of transfers for an account.
    #
    # The transfers included in the calculation can be limited by time range
    # and provided custom filters.
    #
    # @example Find the sum for all $10 :save transfers in all :checking accounts in the current month (assume the date is January 30, 2014).
    #   time_range = DoubleEntry::TimeRange.make(2014, 1)
    #   class ::DoubleEntry::Line
    #     scope :ten_dollar_transfers, -> { where(:amount => 10_00) }
    #   end
    #   DoubleEntry.aggregate(:sum, :checking, :save, range: time_range, filter: [:ten_dollar_transfers])
    # @param function [Symbol] The function to perform on the set of transfers.
    #   Valid functions are :sum, :count, and :average
    # @param account [Symbol] The symbol identifying the account to perform
    #   the aggregate calculation on. As specified in the account configuration.
    # @param code [Symbol] The application specific code for the type of
    #   transfer to perform an aggregate calculation on. As specified in the
    #   transfer configuration.
    # @option options :range [DoubleEntry::TimeRange] Only include transfers
    #   in the given time range in the calculation.
    # @option options :filter [Array[Symbol], or Array[Hash<Symbol,Parameter>]]
    #   A custom filter to apply before performing the aggregate calculation.
    #   Currently, filters must be monkey patched as scopes into the DoubleEntry::Line
    #   class in order to be used as filters, as the example shows.
    #   If the filter requires a parameter, it must be given in a Hash, otherwise
    #   pass an array with the symbol names for the defined scopes.
    # @return Returns a Money object for :sum and :average calculations, or a
    #   Fixnum for :count calculations.
    # @raise [Reporting::AggregateFunctionNotSupported] The provided function
    #   is not supported.
    #
    def aggregate(function, account, code, options = {})
      Aggregate.new(function, account, code, options).formatted_amount
    end

    # Perform an aggregate calculation on a set of transfers for an account
    # and return the results in an array partitioned by a time range type.
    #
    # The transfers included in the calculation can be limited by a time range
    # and provided custom filters.
    #
    # @example Find the number of all $10 :save transfers in all :checking accounts per month for the entire year (Assume the year is 2014).
    #   DoubleEntry.aggregate_array(:sum, :checking, :save, range_type: 'month', start: '2014-01-01', finish: '2014-12-31')
    # @param function [Symbol] The function to perform on the set of transfers.
    #   Valid functions are :sum, :count, and :average
    # @param account [Symbol] The symbol identifying the account to perform
    #   the aggregate calculation on. As specified in the account configuration.
    # @param code [Symbol] The application specific code for the type of
    #   transfer to perform an aggregate calculation on. As specified in the
    #   transfer configuration.
    # @option options :filter [Array[Symbol], or Array[Hash<Symbol,Parameter>]]
    #   A custom filter to apply before performing the aggregate calculation.
    #   Currently, filters must be monkey patched as scopes into the DoubleEntry::Line
    #   class in order to be used as filters, as the example shows.
    #   If the filter requires a parameter, it must be given in a Hash, otherwise
    #   pass an array with the symbol names for the defined scopes.
    # @option options :range_type [String] The type of time range to return data
    #   for.  For example, specifying 'month' will return an array of the resulting
    #   aggregate calculation for each month.
    #   Valid range_types are 'hour', 'day', 'week', 'month', and 'year'
    # @option options :start [String] The start date for the time range to perform
    #   calculations in.  The default start date is the start_of_business (can
    #   be specified in configuration).
    #   The format of the string must be as follows: 'YYYY-mm-dd'
    # @option options :finish [String] The finish (or end) date for the time range
    #   to perform calculations in.  The default finish date is the current date.
    #   The format of the string must be as follows: 'YYYY-mm-dd'
    # @return [Array[Money/Fixnum]] Returns an array of Money objects for :sum
    #   and :average calculations, or an array of Fixnum for :count calculations.
    #   The array is indexed by the range_type.  For example, if range_type is
    #   specified as 'month', each index in the array will represent a month.
    # @raise [Reporting::AggregateFunctionNotSupported] The provided function
    #   is not supported.
    #
    def aggregate_array(function, account, code, options = {})
      AggregateArray.new(function, account, code, options)
    end

    # Identify the scopes with the given account identifier holding at least
    # the provided minimum balance.
    #
    # @example Find users with at least $1,000,000 in their savings accounts
    #   DoubleEntry.scopes_with_minimum_balance_for_account(
    #     Money.new(1_000_000_00),
    #     :savings
    #   ) # might return user ids: [ 1423, 12232, 34729 ]
    # @param minimum_balance [Money] Minimum account balance a scope must have
    #   to be included in the result set.
    # @param account_identifier [Symbol]
    # @return [Array<Fixnum>] Scopes
    def scopes_with_minimum_balance_for_account(minimum_balance, account_identifier)
      select_values(sanitize_sql_array([<<-SQL, account_identifier, minimum_balance.cents])).map {|scope| scope.to_i }
        SELECT scope
          FROM #{AccountBalance.table_name}
         WHERE account = ?
           AND balance >= ?
      SQL
    end

  private

    delegate :connection, :to => ActiveRecord::Base
    delegate :select_values, :to => :connection

    def sanitize_sql_array(sql_array)
      ActiveRecord::Base.send(:sanitize_sql_array, sql_array)
    end
  end
end
