# encoding: utf-8
require 'double_entry/reporting/aggregate'
require 'double_entry/reporting/aggregate_array'
require 'double_entry/reporting/time_range'
require 'double_entry/reporting/day_range'
require 'double_entry/reporting/hour_range'
require 'double_entry/reporting/week_range'
require 'double_entry/reporting/month_range'
require 'double_entry/reporting/year_range'
require 'double_entry/reporting/line_aggregate'
require 'double_entry/reporting/line_aggregate_filter'
require 'double_entry/reporting/line_metadata_filter'
require 'double_entry/reporting/time_range_array'

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
    # @example Find the sum for all $10 :save transfers in all :checking accounts in the current month, made by Australian users (assume the date is January 30, 2014).
    #   time_range = DoubleEntry::Reporting::TimeRange.make(2014, 1)
    #
    #   DoubleEntry::Line.class_eval do
    #     scope :specific_transfer_amount, ->(amount) { where(:amount => amount.fractional) }
    #   end
    #
    #   DoubleEntry::Reporting.aggregate(
    #     :sum,
    #     :checking,
    #     :save,
    #     time_range,
    #     :filter => [
    #       :scope    => {
    #         :name      => :specific_transfer_amount,
    #         :arguments => [Money.new(10_00)]
    #       },
    #       :metadata => {
    #         :user_location => 'AU'
    #       },
    #     ]
    #   )
    # @param [Symbol] function The function to perform on the set of transfers.
    #   Valid functions are :sum, :count, and :average
    # @param [Symbol] account The symbol identifying the account to perform
    #   the aggregate calculation on. As specified in the account configuration.
    # @param [Symbol] code The application specific code for the type of
    #   transfer to perform an aggregate calculation on. As specified in the
    #   transfer configuration.
    # @param [DoubleEntry::Reporting::TimeRange] range Only include transfers in
    #   the given time range in the calculation.
    # @param [Symbol] partner_account The symbol identifying the partner account
    #   to perform the aggregate calculatoin on.  As specified in the account
    #   configuration.
    # @param [Array<Hash<Symbol,Hash<Symbol,Object>>>] filter
    #   An array of custom filter to apply before performing the aggregate
    #   calculation. Filters can be either scope filters, where the name must be
    #   specified, or they can be metadata filters, where the key/value pair to
    #   match on must be specified.
    #   Scope filters must be monkey patched as scopes into the DoubleEntry::Line
    #   class, as the example above shows. Scope filters may also take a list of
    #   arguments to pass into the monkey patched scope, and, if provided, must
    #   be contained within an array.
    # @return [Money, Integer] Returns a Money object for :sum and :average
    #   calculations, or a Integer for :count calculations.
    # @raise [Reporting::AggregateFunctionNotSupported] The provided function
    #   is not supported.
    #
    def aggregate(function:, account:, code:, range:, partner_account: nil, filter: nil)
      Aggregate.formatted_amount(function: function, account: account, code: code, range: range,
                                 partner_account: partner_account, filter: filter)
    end

    # Perform an aggregate calculation on a set of transfers for an account
    # and return the results in an array partitioned by a time range type.
    #
    # The transfers included in the calculation can be limited by a time range
    # and provided custom filters.
    #
    # @example Find the number of all $10 :save transfers in all :checking accounts per month for the entire year (Assume the year is 2014).
    #   DoubleEntry::Reporting.aggregate_array(
    #     :sum,
    #     :checking,
    #     :save,
    #     :range_type => 'month',
    #     :start      => '2014-01-01',
    #     :finish     => '2014-12-31',
    #   )
    # @param [Symbol] function The function to perform on the set of transfers.
    #   Valid functions are :sum, :count, and :average
    # @param [Symbol] account The symbol identifying the account to perform
    #   the aggregate calculation on. As specified in the account configuration.
    # @param [Symbol] code The application specific code for the type of
    #   transfer to perform an aggregate calculation on. As specified in the
    #   transfer configuration.
    # @param [Symbol] partner_account The symbol identifying the partner account
    #   to perform the aggregative calculation on.  As specified in the account
    #   configuration.
    # @param [Array<Symbol>, Array<Hash<Symbol, Object>>] filter
    #   A custom filter to apply before performing the aggregate calculation.
    #   Currently, filters must be monkey patched as scopes into the
    #   DoubleEntry::Line class in order to be used as filters, as the example
    #   shows. If the filter requires a parameter, it must be given in a Hash,
    #   otherwise pass an array with the symbol names for the defined scopes.
    # @param [String] range_type The type of time range to return data
    #   for. For example, specifying 'month' will return an array of the resulting
    #   aggregate calculation for each month.
    #   Valid range_types are 'hour', 'day', 'week', 'month', and 'year'
    # @param [String] start The start date for the time range to perform
    #   calculations in.  The default start date is the start_of_business (can
    #   be specified in configuration).
    #   The format of the string must be as follows: 'YYYY-mm-dd'
    # @param [String] finish The finish (or end) date for the time range
    #   to perform calculations in.  The default finish date is the current date.
    #   The format of the string must be as follows: 'YYYY-mm-dd'
    # @return [Array<Money, Integer>] Returns an array of Money objects for :sum
    #   and :average calculations, or an array of Integer for :count calculations.
    #   The array is indexed by the range_type.  For example, if range_type is
    #   specified as 'month', each index in the array will represent a month.
    # @raise [Reporting::AggregateFunctionNotSupported] The provided function
    #   is not supported.
    #
    def aggregate_array(function:, account:, code:, partner_account: nil, filter: nil,
                        range_type: nil, start: nil, finish: nil)
      AggregateArray.new(function: function, account: account, code: code, partner_account: partner_account,
                         filter: filter, range_type: range_type, start: start, finish: finish)
    end

    # Identify the scopes with the given account identifier holding at least
    # the provided minimum balance.
    #
    # @example Find users with at least $1,000,000 in their savings accounts
    #   DoubleEntry::Reporting.scopes_with_minimum_balance_for_account(
    #     1_000_000.dollars,
    #     :savings,
    #   ) # might return the user ids: [ 1423, 12232, 34729 ]
    # @param [Money] minimum_balance Minimum account balance a scope must have
    #   to be included in the result set.
    # @param [Symbol] account_identifier
    # @return [Array<Integer>] Scopes
    #
    def scopes_with_minimum_balance_for_account(minimum_balance, account_identifier)
      select_values(sanitize_sql_array([<<-SQL, account_identifier, minimum_balance.cents])).map(&:to_i)
        SELECT scope
          FROM #{AccountBalance.table_name}
         WHERE account = ?
           AND balance >= ?
      SQL
    end

    # This is used by the concurrency test script.
    #
    # @api private
    # @return [Boolean] true if all the amounts for an account add up to the final balance,
    #   which they always should.
    #
    def reconciled?(account)
      scoped_lines = Line.where(:account => "#{account.identifier}")
      scoped_lines = scoped_lines.where(:scope => "#{account.scope_identity}") if account.scoped?
      sum_of_amounts = scoped_lines.sum(:amount)
      final_balance  = scoped_lines.order(:id).last[:balance]
      cached_balance = AccountBalance.find_by_account(account)[:balance]
      final_balance == sum_of_amounts && final_balance == cached_balance
    end

  private

    delegate :connection, :to => ActiveRecord::Base
    delegate :select_values, :to => :connection

    def sanitize_sql_array(sql_array)
      ActiveRecord::Base.send(:sanitize_sql_array, sql_array)
    end
  end
end
