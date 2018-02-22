# encoding: utf-8
module DoubleEntry
  module Reporting
    class YearRange < TimeRange
      attr_reader :year

      def initialize(options)
        super options

        year_start = Time.local(@year, 1, 1)
        @start = year_start
        @finish = year_start.end_of_year
      end

      def self.current
        new(:year => Time.now.year)
      end

      def self.from_time(time)
        new(:year => time.year)
      end

      def ==(other)
        year == other.year
      end

      def previous
        YearRange.new(:year => year - 1)
      end

      def next
        YearRange.new(:year => year + 1)
      end

      def to_s
        year.to_s
      end
    end
  end
end
