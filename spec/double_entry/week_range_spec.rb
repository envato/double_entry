# encoding: utf-8
require 'spec_helper'

describe DoubleEntry::WeekRange do

  it "should start week 1 of a year in the first week that has any day in the year" do
    range = DoubleEntry::WeekRange.new(:year => 2011, :week => 1)
    expect(range.start).to eq Time.parse("2010-12-27 00:00:00")
  end

  it "should handle times in the last week of the year properly" do
    range = DoubleEntry::WeekRange.from_time(Time.parse("2010-12-29 11:30:00"))
    expect(range.year).to eq 2011
    expect(range.week).to eq 1
    expect(range.start).to eq Time.parse("2010-12-27 00:00:00")
  end

end
