# encoding: utf-8
module DoubleEntry
  # We use a particularly crazy week numbering system: week 1 of any given year
  # is the first week with any days that fall into that year.
  #
  # So, for example, week 1 of 2011 starts on 27 Dec 2010.
  class WeekRange < TimeRange
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

    def self.from_time(time)
      WeekRange.new.from_time(time)
    end

    def self.current
      from_time(Time.now)
    end

    def self.reportable_weeks
      WeekRange.new.reportable_weeks
    end

    def previous
      WeekRange.from_time(@start - 1.week)
    end

    def next
      WeekRange.from_time(@start + 1.week)
    end

    def ==(other)
      (self.week == other.week) and (self.year == other.year)
    end

    def reportable_weeks
      first   = earliest_week
      current = WeekRange.current
      loop  = first
      weeks = [first]

      while loop != current
        loop = loop.next
        weeks << loop
      end

      weeks
    end

    def from_time(time)
      year = time.end_of_week.year
      week = ((time.beginning_of_week - start_of_year(year)) / 1.week).floor + 1
      WeekRange.new(:year => year, :week => week)
    end

    def all_time
      WeekRange.new(:year => year, :week => week, :range_type => :all_time)
    end

    def to_s
      "#{year}, Week #{week}"
    end

  private

    def earliest_week
      WeekRange.from_time(DoubleEntry::Reporting.configuration.start_of_business)
    end

    def week_and_year_to_time(week, year)
      start_of_year(year) + (week-1).weeks
    end

    def start_of_year(year)
      Time.local(year, 1, 1).beginning_of_week
    end

  end
end
