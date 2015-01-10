module DoubleEntry::Reporting
 RSpec.describe TimeRangeArray do
  describe '.make' do
    subject(:time_range_array) { TimeRangeArray.make(range_type, start, finish) }

    context 'for "hour" range type' do
      let(:range_type) { 'hour' }

      context 'given start is "2007-05-03 15:00:00" and finish is "2007-05-03 18:00:00"' do
        let(:start)  { '2007-05-03 15:00:00' }
        let(:finish) { '2007-05-03 18:00:00' }
        it { should eq [
          HourRange.from_time(Time.new(2007, 5, 3, 15)),
          HourRange.from_time(Time.new(2007, 5, 3, 16)),
          HourRange.from_time(Time.new(2007, 5, 3, 17)),
          HourRange.from_time(Time.new(2007, 5, 3, 18)),
        ] }
      end

      context 'given start and finish are nil' do
        it 'should raise an error' do
          expect { TimeRangeArray.make(range_type, nil, nil) }.
            to raise_error 'Must specify start of range'
        end
      end
    end

    context 'for "day" range type' do
      let(:range_type) { 'day' }

      context 'given start is "2007-05-03" and finish is "2007-05-07"' do
        let(:start)  { '2007-05-03' }
        let(:finish) { '2007-05-07' }
        it { should eq [
          DayRange.from_time(Time.new(2007, 5, 3)),
          DayRange.from_time(Time.new(2007, 5, 4)),
          DayRange.from_time(Time.new(2007, 5, 5)),
          DayRange.from_time(Time.new(2007, 5, 6)),
          DayRange.from_time(Time.new(2007, 5, 7)),
        ] }
      end

      context 'given start and finish are nil' do
        it 'should raise an error' do
          expect { TimeRangeArray.make(range_type, nil, nil) }.
            to raise_error 'Must specify start of range'
        end
      end
    end

    context 'for "week" range type' do
      let(:range_type) { 'week' }

      context 'given start is "2007-05-03" and finish is "2007-05-24"' do
        let(:start)  { '2007-05-03' }
        let(:finish) { '2007-05-24' }
        it { should eq [
          WeekRange.from_time(Time.new(2007, 5, 3)),
          WeekRange.from_time(Time.new(2007, 5, 10)),
          WeekRange.from_time(Time.new(2007, 5, 17)),
          WeekRange.from_time(Time.new(2007, 5, 24)),
        ] }
      end

      context 'given start and finish are nil' do
        it 'should raise an error' do
          expect { TimeRangeArray.make(range_type, nil, nil) }.
            to raise_error 'Must specify start of range'
        end
      end
    end

    context 'for "month" range type' do
      let(:range_type) { 'month' }

      context 'given start is "2007-05-03" and finish is "2007-08-24"' do
        let(:start)  { '2007-05-03' }
        let(:finish) { '2007-08-24' }
        it { should eq [
          MonthRange.from_time(Time.new(2007, 5)),
          MonthRange.from_time(Time.new(2007, 6)),
          MonthRange.from_time(Time.new(2007, 7)),
          MonthRange.from_time(Time.new(2007, 8)),
        ] }
      end

      context 'given finish is nil' do
        let(:start)  { '2006-08-03' }
        let(:finish) { nil }

        context 'and the date is "2007-04-13"' do
          before { Timecop.freeze(Time.new(2007, 4, 13)) }

          it { should eq [
            MonthRange.from_time(Time.new(2006, 8)),
            MonthRange.from_time(Time.new(2006, 9)),
            MonthRange.from_time(Time.new(2006, 10)),
            MonthRange.from_time(Time.new(2006, 11)),
            MonthRange.from_time(Time.new(2006, 12)),
            MonthRange.from_time(Time.new(2007, 1)),
            MonthRange.from_time(Time.new(2007, 2)),
            MonthRange.from_time(Time.new(2007, 3)),
            MonthRange.from_time(Time.new(2007, 4)),
          ] }
        end
      end
    end

    context 'for "year" range type' do
      let(:range_type) { 'year' }

      context 'given the date is "2009-11-23"' do
        before { Timecop.freeze(Time.new(2009, 11, 23)) }

        context 'given start is "2007-05-03" and finish is "2008-08-24"' do
          let(:start)  { '2007-05-03' }
          let(:finish) { '2008-08-24' }


          it 'takes notice of start and finish' do
            should eq [
              YearRange.from_time(Time.new(2007)),
              YearRange.from_time(Time.new(2008)),
            ]
          end
        end

        context 'given the start of business is "2006-07-10"' do
          before do
            allow(DoubleEntry::Reporting).
              to receive_message_chain('configuration.start_of_business').
              and_return(Time.new(2006, 7, 10))
          end

          context 'given start and finish are nil' do
            let(:start)  { nil }
            let(:finish) { nil }
            it {
              should eq [
                YearRange.from_time(Time.new(2006)),
                YearRange.from_time(Time.new(2007)),
                YearRange.from_time(Time.new(2008)),
                YearRange.from_time(Time.new(2009)),
              ]
            }
          end
        end
      end
    end

    context 'given an invalid range type "ueue"' do
      it 'should raise an error' do
        expect { TimeRangeArray.make('ueue') }.to raise_error ArgumentError
      end
    end
  end
 end
end
