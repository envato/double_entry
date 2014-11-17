# encoding: utf-8
module DoubleEntry
 module Reporting
  class AggregateArray < Array
    # An AggregateArray is awesome
    # It is useful for making reports
    # It is basically an array of aggregate results,
    # representing a column of data in a report.
    #
    # For example, you could request all sales
    # broken down by month and it would return an array of values
    attr_reader :function, :account, :code, :filter, :range_type, :start, :finish

    def initialize(function, account, code, options)
      @function = function
      @account = account
      @code = code
      @filter = options[:filter]
      @range_type = options[:range_type]
      @start = options[:start]
      @finish = options[:finish]

      retrieve_aggregates
      fill_in_missing_aggregates
      populate_self
    end

    private

    def populate_self
      all_periods.each do |period|
        self << @aggregates[period.key]
      end
    end

    def fill_in_missing_aggregates
      # some aggregates may not have been previously calculated, so we can request them now
      # (this includes aggregates for the still-running period)
      all_periods.each do |period|
        unless @aggregates[period.key]
          @aggregates[period.key] = Reporting.aggregate(function, account, code, :filter => filter, :range => period)
        end
      end
    end

    # get any previously calculated aggregates
    def retrieve_aggregates
      raise ArgumentError.new("Invalid range type '#{range_type}'") unless %w(year month week day hour).include? range_type
      @aggregates = LineAggregate.
        where(:function => function.to_s).
        where(:range_type => 'normal').
        where(:account => account.to_s).
        where(:code => code.to_s).
        where(:filter => filter.inspect).
        where(LineAggregate.arel_table[range_type].not_eq(nil)).
        inject({}) do |hash, result|
          hash[result.key] = Aggregate.formatted_amount(function, result.amount, currency)
          hash
        end
    end

    def all_periods
      TimeRangeArray.make(range_type, start, finish)
    end

    def currency
      DoubleEntry::Account.currency(account)
    end
  end
 end
end
