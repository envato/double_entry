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

      context "My business started on 25th Jan 1970" do
        before do
          DoubleEntry::Reporting.configure do |config|
            config.start_of_business = Time.new(1970, 1, 25)
          end
        end

        it { should eq [
          DoubleEntry::WeekRange.new(year: 1970, week: 4),
          DoubleEntry::WeekRange.new(year: 1970, week: 5),
        ] }
      end
    end

    context "The date is 1st Jan 1970" do
      before { Timecop.freeze(Time.new(1970, 1, 1)) }

      it { should eq [ DoubleEntry::WeekRange.new(year: 1970, week: 1) ] }
    end
  end
end
