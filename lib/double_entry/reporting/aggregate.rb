# encoding: utf-8
module DoubleEntry
 module Reporting
  class Aggregate
    attr_reader :function, :account, :code, :range, :options, :filter

    def initialize(function, account, code, options)
      @function = function.to_s
      raise AggregateFunctionNotSupported unless %w[sum count average].include?(@function)

      @account = account.to_s
      @code = code ? code.to_s : nil
      @options = options
      @range = options[:range]
      @filter = options[:filter]
    end

    def amount(force_recalculation = false)
      if force_recalculation
        clear_old_aggregates
        calculate
      else
        retrieve || calculate
      end
    end

    def formatted_amount
      Aggregate.formatted_amount(function, amount)
    end

    def self.formatted_amount(function, amount)
      safe_amount = amount || 0

      case function.to_s
      when 'count'
        safe_amount
      else
        Money.new(safe_amount)
      end
    end

    private

    def retrieve
      aggregate = LineAggregate.where(field_hash).first
      aggregate.amount if aggregate
    end

    def clear_old_aggregates
      LineAggregate.delete_all(field_hash)
    end

    def calculate
      if range.class == YearRange
        aggregate = calculate_yearly_aggregate
      else
        aggregate = LineAggregate.aggregate(function, account, code, range, filter)
      end

      if range_is_complete?
        fields = field_hash
        fields[:amount] = aggregate || 0
        LineAggregate.create! fields
      end

      aggregate
    end

    def calculate_yearly_aggregate
      # We calculate yearly aggregates by combining monthly aggregates
      # otherwise they will get excruciatingly slow to calculate
      # as the year progresses.  (I am thinking mainly of the 'current' year.)
      # Combining monthly aggregates will mean that the figure will be partially memoized
      case function.to_s
      when 'average'
        calculate_yearly_average
      else
        zero = Aggregate.formatted_amount(function, 0)

        result = (1..12).inject(zero) do |total, month|
          total += Reporting.aggregate(function, account, code,
                                      :range => MonthRange.new(:year => range.year, :month => month), :filter => filter)
        end

        result = result.cents if result.class == Money
        result
      end
    end

    def calculate_yearly_average
      # need this seperate function, because an average of averages is not the correct average
      sum = Reporting.aggregate(:sum, account, code,
                               :range => YearRange.new(:year => range.year), :filter => filter)
      count = Reporting.aggregate(:count, account, code,
                                 :range => YearRange.new(:year => range.year), :filter => filter)
      (count == 0) ? 0 : (sum / count).cents
    end

    def range_is_complete?
      Time.now > range.finish
    end

    def field_hash
      {
        :function => function,
        :account => account,
        :code => code,
        :year => range.year,
        :month => range.month,
        :week => range.week,
        :day => range.day,
        :hour => range.hour,
        :filter => filter.inspect,
        :range_type => range.range_type.to_s
      }
    end
  end
 end
end
