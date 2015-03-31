# encoding: utf-8
module DoubleEntry
  module Reporting
    class DayRange < TimeRange
      attr_reader :year, :week, :day

      def initialize(options)
        super options

        @week = options[:week]
        @day = options[:day]
        week_range = WeekRange.new(options)

        @start = week_range.start + (options[:day] - 1).days
        @finish = @start.end_of_day
      end

      def self.from_time(time)
        week_range = WeekRange.from_time(time)
        DayRange.new(:year => week_range.year, :week => week_range.week, :day => time.wday == 0 ? 7 : time.wday)
      end

      def previous
        DayRange.from_time(@start - 1.day)
      end

      def next
        DayRange.from_time(@start + 1.day)
      end

      def ==(other)
        week == other.week &&
          year == other.year &&
          day == other.day
      end

      def to_s
        start.strftime("%Y, %a %b %d")
      end
    end
  end
end
