# encoding: utf-8
module DoubleEntry
 module Reporting
  class TimeRangeArray
    class << self

      def make(range_type, start, finish = nil)
        raise "Must specify range for #{range_type}-by-#{range_type} reports" if start == nil

        case range_type
        when 'hour'
          make_array HourRange, start, finish
        when 'day'
          make_array DayRange, start, finish
        when 'week'
          make_array WeekRange, start, finish
        when 'month'
          make_array MonthRange, start, finish
        when 'year'
          make_array YearRange, start
        else
          raise ArgumentError.new("Invalid range type '#{range_type}'")
        end
      end

      private

      def make_array(type, start, finish = nil)
        start = type.from_time(Time.parse(start))
        finish = type.from_time(Time.parse(finish)) if finish

        loop = start
        last = finish || type.current
        results = [loop]
        while(loop != last) do
          loop = loop.next
          results << loop
        end

        results
      end
    end
  end
 end
end
