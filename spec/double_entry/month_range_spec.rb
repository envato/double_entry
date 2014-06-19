# encoding: utf-8
require "spec_helper"
describe DoubleEntry::MonthRange do

  describe "::from_time" do
    subject(:from_time) { DoubleEntry::MonthRange.from_time(given_time) }

    context "given the Time 31st March 2012" do
      let(:given_time) { Time.new(2012, 3, 31) }
      its(:year) { should eq 2012 }
      its(:month) { should eq 3 }
    end

    context "given the Date 31st March 2012" do
      let(:given_time) { Date.parse("2012-03-31") }
      its(:year) { should eq 2012 }
      its(:month) { should eq 3 }
    end
  end

  describe "::reportable_months" do
    subject(:reportable_months) { DoubleEntry::MonthRange.reportable_months }

    context "The date is 1st March 1970" do
      before { Timecop.freeze(Time.new(1970, 3, 1)) }
      it { should eq [
        DoubleEntry::MonthRange.new(year: 1970, month: 1),
        DoubleEntry::MonthRange.new(year: 1970, month: 2),
        DoubleEntry::MonthRange.new(year: 1970, month: 3),
      ] }
    end

    context "The date is 1st Jan 1970" do
      before { Timecop.freeze(Time.new(1970, 1, 1)) }
      it { should eq [ DoubleEntry::MonthRange.new(year: 1970, month: 1) ] }
    end

    context "Given a start time of 3rd Dec 1982" do
      subject(:reportable_months) { DoubleEntry::MonthRange.reportable_months(from: Time.new(1982, 12, 3)) }

      context "The date is 2nd Feb 1983" do
        before { Timecop.freeze(Time.new(1983, 2, 2)) }
        it { should eq [
          DoubleEntry::MonthRange.new(year: 1982, month: 12),
          DoubleEntry::MonthRange.new(year: 1983, month: 1),
          DoubleEntry::MonthRange.new(year: 1983, month: 2),
        ] }
      end
    end
  end
end
