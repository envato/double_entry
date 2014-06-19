# encoding: utf-8
require "spec_helper"
describe DoubleEntry::MonthRange do

  describe "::reportable_months" do
    subject(:reportable_months) { DoubleEntry::MonthRange.reportable_months }

    context "The date is 1st March 1970" do
      before { Timecop.freeze(Time.new(1970, 3, 1)) }

      it { should eq [
        DoubleEntry::MonthRange.new(year: 1970, month: 1),
        DoubleEntry::MonthRange.new(year: 1970, month: 2),
        DoubleEntry::MonthRange.new(year: 1970, month: 3),
      ] }

      context "My business started on 5th Feb 1970" do
        before do
          DoubleEntry::Reporting.configure do |config|
            config.start_of_business = Time.new(1970, 2, 5)
          end
        end

        it { should eq [
          DoubleEntry::MonthRange.new(year: 1970, month: 2),
          DoubleEntry::MonthRange.new(year: 1970, month: 3),
        ] }
      end
    end

    context "The date is 1st Jan 1970" do
      before { Timecop.freeze(Time.new(1970, 1, 1)) }

      it { should eq [ DoubleEntry::MonthRange.new(year: 1970, month: 1) ] }
    end

  end
end
