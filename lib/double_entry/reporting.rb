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

    def aggregate(function, account, code, options = {})
      Aggregate.new(function, account, code, options).formatted_amount
    end

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

    # This is used by the concurrency test script.
    #
    # @api private
    # @return [Boolean] true if all the amounts for an account add up to the final balance,
    #   which they always should.
    def reconciled?(account)
      scoped_lines = Line.where(:account => "#{account.identifier}", :scope => "#{account.scope}")
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
