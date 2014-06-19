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

  describe "::reportable_weeks" do
    subject(:reportable_weeks) { DoubleEntry::WeekRange.reportable_weeks }

    context "The date is 1st Feb 1970" do
      before { Timecop.freeze(Time.new(1970, 2, 1)) }
      it { should eq [
        DoubleEntry::WeekRange.new(year: 1970, week: 1),
        DoubleEntry::WeekRange.new(year: 1970, week: 2),
        DoubleEntry::WeekRange.new(year: 1970, week: 3),
        DoubleEntry::WeekRange.new(year: 1970, week: 4),
        DoubleEntry::WeekRange.new(year: 1970, week: 5),
      ] }
    end

    context "The date is 1st Jan 1970" do
      before { Timecop.freeze(Time.new(1970, 1, 1)) }
      it { should eq [ DoubleEntry::WeekRange.new(year: 1970, week: 1) ] }
    end

    context "Given a start time of 3rd Dec 1982" do
      subject(:reportable_weeks) { DoubleEntry::WeekRange.reportable_weeks(from: Time.new(1982, 12, 3)) }

      context "The date is 12nd Jan 1983" do
        before { Timecop.freeze(Time.new(1983, 2, 2)) }
        it { should eq [
          DoubleEntry::WeekRange.new(year: 1982, week: 12),
          DoubleEntry::WeekRange.new(year: 1983, week: 1),
          DoubleEntry::WeekRange.new(year: 1983, week: 2),
        ] }
      end
    end
  end

end
