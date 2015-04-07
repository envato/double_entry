# encoding: utf-8
module DoubleEntry
  module Reporting
    class MonthRange < TimeRange
      class << self
        def from_time(time)
          new(:year => time.year, :month => time.month)
        end

        def current
          from_time(Time.now)
        end

        # Obtain a sequence of MonthRanges from the given start to the current
        # month.
        #
        # @option options :from [Time] Time of the first in the returned sequence
        #   of MonthRanges.
        # @return [Array<MonthRange>]
        def reportable_months(options = {})
          month = options[:from] ? from_time(options[:from]) : earliest_month
          last = current
          [month].tap do |months|
            while month != last
              month = month.next
              months << month
            end
          end
        end

        def earliest_month
          from_time(Reporting.configuration.start_of_business)
        end
      end

      attr_reader :year, :month

      def initialize(options = {})
        super options

        if options.present?
          @month = options[:month]

          month_start = Time.local(year, options[:month], 1)
          @start = month_start
          @finish = month_start.end_of_month

          @start = MonthRange.earliest_month.start if options[:range_type] == :all_time
        end
      end

      def previous
        if month <= 1
          MonthRange.new :year => year - 1, :month => 12
        else
          MonthRange.new :year => year, :month => month - 1
        end
      end

      def next
        if month >= 12
          MonthRange.new :year => year + 1, :month => 1
        else
          MonthRange.new :year => year, :month => month + 1
        end
      end

      def beginning_of_financial_year
        first_month_of_financial_year = Reporting.configuration.first_month_of_financial_year
        year = (month >= first_month_of_financial_year) ? @year : (@year - 1)
        MonthRange.new(:year => year, :month => first_month_of_financial_year)
      end

      alias_method :succ, :next

      def <=>(other)
        start <=> other.start
      end

      def ==(other)
        month == other.month &&
          year == other.year
      end

      def all_time
        MonthRange.new(:year => year, :month => month, :range_type => :all_time)
      end

      def to_s
        start.strftime('%Y, %b')
      end
    end
  end
end
