# encoding: utf-8
module DoubleEntry
  class MonthRange < TimeRange
    attr_reader :year, :month

    def initialize(options = {})
      super options

      if options.present?
        @month = options[:month]

        month_start = Time.local(@year, options[:month], 1)
        @start = month_start
        @finish = month_start.end_of_month

        @start = earliest_month.start if options[:range_type] == :all_time
      end
    end

    def self.from_time(time)
      MonthRange.new(:year => time.year, :month => time.month)
    end

    def self.current
      from_time(Time.now)
    end

    def self.reportable_months
      MonthRange.new.reportable_months
    end

    def previous
      if @month <= 1
        MonthRange.new :year => @year - 1, :month => 12
      else
        MonthRange.new :year => @year, :month => @month - 1
      end
    end

    def next
      if @month >= 12
        MonthRange.new :year => @year + 1, :month => 1
      else
        MonthRange.new :year => @year, :month => @month + 1
      end
    end

    def beginning_of_financial_year
      if month >= 7
        MonthRange.new(:year => @year, :month => 7)
      else
        MonthRange.new(:year => @year-1, :month => 7)
      end
    end

    alias_method :succ, :next

    def <=>(other)
      self.start <=> other.start
    end

    def ==(other)
      (self.month == other.month) and (self.year == other.year)
    end

    def reportable_months
      first = earliest_month
      current = MonthRange.current
      loop = first
      months = [first]

      while loop != current
        loop = loop.next
        months << loop
      end

      months
    end

    def all_time
      MonthRange.new(:year => year, :month => month, :range_type => :all_time)
    end

    def to_s
      start.strftime("%Y, %b")
    end

  private

    def earliest_month
      MonthRange.new(:year => 1970, :month => 1)
    end

  end
end
