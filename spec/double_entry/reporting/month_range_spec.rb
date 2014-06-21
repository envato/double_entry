# encoding: utf-8
require "spec_helper"
module DoubleEntry::Reporting
  describe MonthRange do

  describe "::from_time" do
    subject(:from_time) { MonthRange.from_time(given_time) }

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
    subject(:reportable_months) { MonthRange.reportable_months }

    context "The date is 1st March 1970" do
      before { Timecop.freeze(Time.new(1970, 3, 1)) }

      it { should eq [
        MonthRange.new(year: 1970, month: 1),
        MonthRange.new(year: 1970, month: 2),
        MonthRange.new(year: 1970, month: 3),
      ] }

      context "My business started on 5th Feb 1970" do
        before do
          DoubleEntry::Reporting.configure do |config|
            config.start_of_business = Time.new(1970, 2, 5)
          end
        end

        it { should eq [
          MonthRange.new(year: 1970, month: 2),
          MonthRange.new(year: 1970, month: 3),
        ] }
      end
    end

    context "The date is 1st Jan 1970" do
      before { Timecop.freeze(Time.new(1970, 1, 1)) }

      it { should eq [ MonthRange.new(year: 1970, month: 1) ] }
    end
  end

  describe "::beginning_of_financial_year" do
    let(:month_range) { MonthRange.new(:year => year, :month => month) }
    let(:year) { 2014 }

    context "the first month of the financial year is July" do
      subject(:beginning_of_financial_year) { month_range.beginning_of_financial_year }
      context "returns the current year if the month is after July" do
        let(:month) { 10 }
        it { should eq(MonthRange.new(:year => 2014, :month => 7)) }
      end

      context "returns the previous year if the month is before July" do
        let(:month) { 3 }
        it { should eq(MonthRange.new(:year => 2013, :month => 7)) }
      end
    end

    context "the first month of the financial year is January" do
      subject(:beginning_of_financial_year) { month_range.beginning_of_financial_year }

      before do
        DoubleEntry::Reporting.configure do |config|
          config.first_month_of_financial_year = 1
        end
      end

      context "returns the current year if the month is after January" do
        let(:month) { 10 }
        it { should eq(MonthRange.new(:year => 2014, :month => 1)) }
      end

      context "returns the current year if the month is January" do
        let(:month) { 1 }
        it { should eq(MonthRange.new(:year => 2014, :month => 1)) }
      end
    end

    context "the first month of the financial year is December" do
      subject(:beginning_of_financial_year) { month_range.beginning_of_financial_year }

      before do
        DoubleEntry::Reporting.configure do |config|
          config.first_month_of_financial_year = 12
        end
      end

      context "returns the previous year if the month is before December (in the same year)" do
        let(:month) { 11 }
        it { should eq(MonthRange.new(:year => 2013, :month => 12)) }
      end

      context "returns the previous year if the month is after December (in the next year)" do
        let(:year) { 2015 }
        let(:month) { 1 }
        it { should eq(MonthRange.new(:year => 2014, :month => 12)) }
      end

      context "returns the current year if the month is December" do
        let(:month) { 12 }
        it { should eq(MonthRange.new(:year => 2014, :month => 12)) }
      end
    end

    context "Given a start time of 3rd Dec 1982" do
      subject(:reportable_months) { MonthRange.reportable_months(from: Time.new(1982, 12, 3)) }

      context "The date is 2nd Feb 1983" do
        before { Timecop.freeze(Time.new(1983, 2, 2)) }

        it { should eq [
          MonthRange.new(year: 1982, month: 12),
          MonthRange.new(year: 1983, month: 1),
          MonthRange.new(year: 1983, month: 2),
        ] }
      end
    end
  end
 end
end
