# encoding: utf-8
module DoubleEntry
 module Reporting
  class HourRange < TimeRange
    attr_reader :year, :week, :day, :hour

    def initialize(options)
      super options

      @week = options[:week]
      @day = options[:day]
      @hour = options[:hour]

      day_range = DayRange.new(options)

      @start = day_range.start + options[:hour].hours
      @finish = @start.end_of_hour
    end

    def self.from_time(time)
      day = DayRange.from_time(time)
      HourRange.new :year => day.year, :week => day.week, :day => day.day, :hour => time.hour
    end

    def previous
      HourRange.from_time(@start - 1.hour)
    end

    def next
      HourRange.from_time(@start + 1.hour)
    end

    def ==(other)
      (self.week == other.week) and (self.year == other.year) and (self.day == other.day) and (self.hour == other.hour)
    end

    def to_s
      "#{start.hour}:00:00 - #{start.hour}:59:59"
    end
  end
 end
end
