require 'spec_helper'
describe DoubleEntry::TimeRangeArray do
  describe '.make' do
    subject(:time_range_array) { DoubleEntry::TimeRangeArray.make(range_type, start, finish) }

    context 'for "hour" range type' do
      let(:range_type) { 'hour' }

      context 'given start is "2007-05-03 15:00:00" and finish is "2007-05-03 18:00:00"' do
        let(:start)  { '2007-05-03 15:00:00' }
        let(:finish) { '2007-05-03 18:00:00' }
        it { should eq [
          DoubleEntry::HourRange.from_time(Time.new(2007, 5, 3, 15)),
          DoubleEntry::HourRange.from_time(Time.new(2007, 5, 3, 16)),
          DoubleEntry::HourRange.from_time(Time.new(2007, 5, 3, 17)),
          DoubleEntry::HourRange.from_time(Time.new(2007, 5, 3, 18)),
        ] }
      end

      context 'given start and finish are nil' do
        it 'should raise an error' do
          expect { DoubleEntry::TimeRangeArray.make(range_type, nil, nil) }.
            to raise_error 'Must specify range for hour-by-hour reports'
        end
      end
    end

    context 'for "day" range type' do
      let(:range_type) { 'day' }

      context 'given start is "2007-05-03" and finish is "2007-05-07"' do
        let(:start)  { '2007-05-03' }
        let(:finish) { '2007-05-07' }
        it { should eq [
          DoubleEntry::DayRange.from_time(Time.new(2007, 5, 3)),
          DoubleEntry::DayRange.from_time(Time.new(2007, 5, 4)),
          DoubleEntry::DayRange.from_time(Time.new(2007, 5, 5)),
          DoubleEntry::DayRange.from_time(Time.new(2007, 5, 6)),
          DoubleEntry::DayRange.from_time(Time.new(2007, 5, 7)),
        ] }
      end

      context 'given start and finish are nil' do
        it 'should raise an error' do
          expect { DoubleEntry::TimeRangeArray.make(range_type, nil, nil) }.
            to raise_error 'Must specify range for day-by-day reports'
        end
      end
    end

    context 'for "week" range type' do
      let(:range_type) { 'week' }

      context 'given start is "2007-05-03" and finish is "2007-05-24"' do
        let(:start)  { '2007-05-03' }
        let(:finish) { '2007-05-24' }
        it { should eq [
          DoubleEntry::WeekRange.from_time(Time.new(2007, 5, 3)),
          DoubleEntry::WeekRange.from_time(Time.new(2007, 5, 10)),
          DoubleEntry::WeekRange.from_time(Time.new(2007, 5, 17)),
          DoubleEntry::WeekRange.from_time(Time.new(2007, 5, 24)),
        ] }
      end

      context 'given start and finish are nil' do
        it 'should raise an error' do
          expect { DoubleEntry::TimeRangeArray.make(range_type, nil, nil) }.
            to raise_error 'Must specify range for week-by-week reports'
        end
      end
    end

    context 'for "month" range type' do
      let(:range_type) { 'month' }

      context 'given start is "2007-05-03" and finish is "2007-08-24"' do
        let(:start)  { '2007-05-03' }
        let(:finish) { '2007-08-24' }
        it { should eq [
          DoubleEntry::MonthRange.from_time(Time.new(2007, 5)),
          DoubleEntry::MonthRange.from_time(Time.new(2007, 6)),
          DoubleEntry::MonthRange.from_time(Time.new(2007, 7)),
          DoubleEntry::MonthRange.from_time(Time.new(2007, 8)),
        ] }
      end

      context 'given finish is nil' do
        let(:start)  { '2006-08-03' }
        let(:finish) { nil }

        context 'and the date is "2007-04-13"' do
          before { Timecop.freeze(Time.new(2007, 4, 13)) }

          it { should eq [
            DoubleEntry::MonthRange.from_time(Time.new(2006, 8)),
            DoubleEntry::MonthRange.from_time(Time.new(2006, 9)),
            DoubleEntry::MonthRange.from_time(Time.new(2006, 10)),
            DoubleEntry::MonthRange.from_time(Time.new(2006, 11)),
            DoubleEntry::MonthRange.from_time(Time.new(2006, 12)),
            DoubleEntry::MonthRange.from_time(Time.new(2007, 1)),
            DoubleEntry::MonthRange.from_time(Time.new(2007, 2)),
            DoubleEntry::MonthRange.from_time(Time.new(2007, 3)),
            DoubleEntry::MonthRange.from_time(Time.new(2007, 4)),
          ] }
        end
      end
    end

    context 'for "year" range type' do
      let(:range_type) { 'year' }

      context 'given start is "2007-05-03" and finish is "2008-08-24"' do
        let(:start)  { '2007-05-03' }
        let(:finish) { '2008-08-24' }

        context 'and the date is "2009-11-23"' do
          before { Timecop.freeze(Time.new(2009, 11, 23)) }

          it 'takes no notice of start and finish' do
            should eq [
              DoubleEntry::YearRange.from_time(Time.new(2007)),
              DoubleEntry::YearRange.from_time(Time.new(2008)),
              DoubleEntry::YearRange.from_time(Time.new(2009)),
            ]
          end

          context 'given finish is nil' do
            let(:start)  { '2006-08-03' }
            let(:finish) { nil }
            it {
              should eq [
                DoubleEntry::YearRange.from_time(Time.new(2006)),
                DoubleEntry::YearRange.from_time(Time.new(2007)),
                DoubleEntry::YearRange.from_time(Time.new(2008)),
                DoubleEntry::YearRange.from_time(Time.new(2009)),
              ]
            }
          end
        end
      end
    end

    context 'given an invalid range type "ueue"' do
      it 'should raise an error' do
        expect { DoubleEntry::TimeRangeArray.make('ueue') }.to raise_error ArgumentError
      end
    end
  end
end
