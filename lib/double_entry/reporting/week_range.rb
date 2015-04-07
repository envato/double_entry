# encoding: utf-8
module DoubleEntry
  module Reporting
    # We use a particularly crazy week numbering system: week 1 of any given year
    # is the first week with any days that fall into that year.
    #
    # So, for example, week 1 of 2011 starts on 27 Dec 2010.
    class WeekRange < TimeRange
      class << self
        def from_time(time)
          date = time.to_date
          week = date.cweek
          year = date.end_of_week.year

          if date.beginning_of_week.year != year
            week = 1
          elsif date.beginning_of_year.cwday > Date::DAYNAMES.index('Thursday')
            week += 1
          end

          new(:year => year, :week => week)
        end

        def current
          from_time(Time.now)
        end

        # Obtain a sequence of WeekRanges from the given start to the current
        # week.
        #
        # @option options :from [Time] Time of the first in the returned sequence
        #   of WeekRanges.
        # @return [Array<WeekRange>]
        def reportable_weeks(options = {})
          week = options[:from] ? from_time(options[:from]) : earliest_week
          last_in_sequence = current
          [week].tap do |weeks|
            while week != last_in_sequence
              week = week.next
              weeks << week
            end
          end
        end

      private

        def start_of_year(year)
          Time.local(year, 1, 1).beginning_of_week
        end

        def earliest_week
          from_time(Reporting.configuration.start_of_business)
        end
      end

      attr_reader :year, :week

      def initialize(options = {})
        super options

        if options.present?
          @week = options[:week]

          @start  = week_and_year_to_time(@week, @year)
          @finish = @start.end_of_week

          @start = earliest_week.start if options[:range_type] == :all_time
        end
      end

      def previous
        from_time(@start - 1.week)
      end

      def next
        from_time(@start + 1.week)
      end

      def ==(other)
        week == other.week &&
          year == other.year
      end

      def all_time
        self.class.new(:year => year, :week => week, :range_type => :all_time)
      end

      def to_s
        "#{year}, Week #{week}"
      end

    private

      def from_time(time)
        self.class.from_time(time)
      end

      def earliest_week
        self.class.send(:earliest_week)
      end

      def week_and_year_to_time(week, year)
        self.class.send(:start_of_year, year) + (week - 1).weeks
      end
    end
  end
end
