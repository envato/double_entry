# encoding: utf-8
module DoubleEntry
  module Reporting
    class TimeRange
      attr_reader :start, :finish
      attr_reader :year, :month, :week, :day, :hour, :range_type

      def self.make(options = {})
        @options = options
        case
        when options[:year] && options[:week] && options[:day] && options[:hour]
          HourRange.new(options)
        when options[:year] && options[:week] && options[:day]
          DayRange.new(options)
        when options[:year] && options[:week]
          WeekRange.new(options)
        when options[:year] && options[:month]
          MonthRange.new(options)
        when options[:year]
          YearRange.new(options)
        else
          fail "Invalid range information #{options}"
        end
      end

      def self.range_from_time_for_period(start_time, period_name)
        case period_name
        when 'month'
          YearRange.from_time(start_time)
        when 'week'
          YearRange.from_time(start_time)
        when 'day'
          MonthRange.from_time(start_time)
        when 'hour'
          DayRange.from_time(start_time)
        end
      end

      def include?(time)
        time >= @start &&
          time <= @finish
      end

      def initialize(options)
        @year = options[:year]
        @range_type = options[:range_type] || :normal
        @month = @week = @day = @hour = nil
      end

      def key
        "#{@year}:#{@month}:#{@week}:#{@day}:#{@hour}"
      end

      def human_readable_name
        self.class.name.gsub('DoubleEntry::Reporting::', '').gsub('Range', '')
      end
    end
  end
end
