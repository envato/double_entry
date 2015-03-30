# encoding: utf-8
module DoubleEntry
  module Reporting
    RSpec.describe TimeRange do
      it 'should correctly calculate a month range' do
        ar = TimeRange.make(:year => 2009, :month => 10)
        expect(ar.start.to_s).to eq Time.mktime(2009, 10, 1, 0, 0, 0).to_s
        expect(ar.finish.to_s).to eq Time.mktime(2009, 10, 31, 23, 59, 59).to_s
      end

      it "should correctly calculate the beginning of the financial year" do
        range = TimeRange.make(:year => 2009, :month => 6).beginning_of_financial_year
        expect(range.month).to eq 7
        expect(range.year).to eq 2008
        range = TimeRange.make(:year => 2009, :month => 7).beginning_of_financial_year
        expect(range.month).to eq 7
        expect(range.year).to eq 2009
      end

      it "should correctly calculate the current week range for New Year's Day" do
        Timecop.freeze Time.mktime(2009, 1, 1) do
          expect(WeekRange.current.week).to eq 1
        end
      end

      it "should correctly calculate the current week range for the first Sunday in the year after New Years" do
        Timecop.freeze Time.mktime(2009, 1, 4) do
          expect(WeekRange.current.week).to eq 1
        end
      end

      it "should correctly calculate the current week range for the first Monday in the year after New Years" do
        Timecop.freeze Time.mktime(2009, 1, 5) do
          expect(WeekRange.current.week).to eq 2
        end
      end

      it "should correctly calculate the current week range for my birthday" do
        Timecop.freeze Time.mktime(2009, 3, 27) do
          expect(WeekRange.current.week).to eq 13
        end
      end
    end
  end
end
