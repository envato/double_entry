# encoding: utf-8
module DoubleEntry
  module Reporting
    class Aggregate
      attr_reader :function, :account, :partner_account, :code, :range, :filter, :currency

      def self.formatted_amount(function:, account:, code:, range:, partner_account: nil, filter: nil)
        new(
          function: function,
          account: account,
          code: code,
          range: range,
          partner_account: partner_account,
          filter: filter,
        ).formatted_amount
      end

      def initialize(function:, account:, code:, range:, partner_account: nil, filter: nil)
        @function = function.to_s
        fail AggregateFunctionNotSupported unless %w(sum count average).include?(@function)

        @account         = account
        @code            = code.try(:to_s)
        @range           = range
        @partner_account = partner_account
        @filter          = filter
        @currency        = DoubleEntry::Account.currency(account)
      end

      def amount(force_recalculation = false)
        if force_recalculation
          clear_old_aggregates
          calculate
        else
          retrieve || calculate
        end
      end

      def formatted_amount(value = amount)
        value ||= 0
        if function == 'count'
          value
        else
          Money.new(value, currency)
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
          aggregate = LineAggregate.aggregate(
            function: function,
            account: account,
            partner_account: partner_account,
            code: code,
            range: range,
            named_scopes: filter
          )
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
        if function == 'average'
          calculate_yearly_average
        else
          result = (1..12).inject(formatted_amount(0)) do |total, month|
            total + Aggregate.new(function: function, account: account, code: code,
                                  range: MonthRange.new(:year => range.year, :month => month),
                                  partner_account: partner_account, filter: filter).formatted_amount
          end
          result.is_a?(Money) ? result.cents : result
        end
      end

      def calculate_yearly_average
        # need this seperate function, because an average of averages is not the correct average
        year_range = YearRange.new(:year => range.year)
        sum = Aggregate.new(function: :sum, account: account, code: code, range: year_range,
                            partner_account: partner_account, filter: filter).formatted_amount
        count = Aggregate.new(function: :count, account: account, code: code, range: year_range,
                              partner_account: partner_account, filter: filter).formatted_amount
        (count == 0) ? 0 : (sum / count).cents
      end

      def range_is_complete?
        Time.now > range.finish
      end

      def field_hash
        {
          :function        => function,
          :account         => account,
          :partner_account => partner_account,
          :code            => code,
          :year            => range.year,
          :month           => range.month,
          :week            => range.week,
          :day             => range.day,
          :hour            => range.hour,
          :filter          => filter.inspect,
          :range_type      => range.range_type.to_s,
        }
      end
    end
  end
end
