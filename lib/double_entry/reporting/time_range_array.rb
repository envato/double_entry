# encoding: utf-8
module DoubleEntry
  module Reporting
    class TimeRangeArray

      attr_reader :type, :require_start
      alias_method :require_start?, :require_start

      def initialize(options = {})
        @type = options[:type]
        @require_start = options[:require_start]
      end

      def make(start = nil, finish = nil)
        start = start_range(start)
        finish = finish_range(finish)
        [ start ].tap do |array|
          while start != finish
            start = start.next
            array << start
          end
        end
      end

      def start_range(start = nil)
        raise "Must specify start of range" if start.blank? && require_start?
        start_time = start ? Time.parse(start) : Reporting.configuration.start_of_business
        type.from_time(start_time)
      end

      def finish_range(finish = nil)
        finish ? type.from_time(Time.parse(finish)) : type.current
      end

      FACTORIES = {
        'hour'  => new(:type => HourRange,  :require_start => true),
        'day'   => new(:type => DayRange,   :require_start => true),
        'week'  => new(:type => WeekRange,  :require_start => true),
        'month' => new(:type => MonthRange, :require_start => false),
        'year'  => new(:type => YearRange,  :require_start => false),
      }

      def self.make(range_type, start = nil, finish = nil)
        factory = FACTORIES[range_type]
        raise ArgumentError.new("Invalid range type '#{range_type}'") unless factory
        factory.make(start, finish)
      end

    end
  end
end
