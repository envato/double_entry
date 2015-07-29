module DoubleEntry
  module Reporting
    RSpec.describe Aggregate do
      include PerformanceHelper
      let(:user) { User.make! }

      context '23,520 transfers spread out over 8 years' do
        before do # setup takes about 191s
          (2008..2015).each do |year|
            (1..12).each do |month|
              (1..28).each do |day|
                Timecop.freeze Time.local(year, month, day) do
                  10.times { perform_deposit user, 1_00 }
                  # TODO: perform_deposit_with_metadata
                end
              end
            end
          end
        end

        it 'should calculate monthly all_time ranges quickly' do
          start_profiling
          (2008..2015).each do |year|
            (1..12).each do |month|
              Reporting.aggregate(
                :sum, :savings, :bonus,
                :range => TimeRange.make(:year => year, :month => month, :range_type => :all_time)
              )
            end
          end
          result = stop_profiling('aggregate')
          expect(total_time(result)).to be_faster_than(:local => 2.5, :ci => 2.5)
        end
      end

      context '23,520 transfers in a single day' do
        before do # setup takes about 170s
          Timecop.freeze Time.local(2015, 06, 30) do
            23_520.times { perform_deposit user, 1_00 }
            # TODO: perform_deposit_with_metadata
          end
        end

        it 'should calculate monthly all_time ranges quickly' do
          start_profiling
          # TODO: aggregate with metadata filter
          Reporting.aggregate(
            :sum, :savings, :bonus,
            :range => TimeRange.make(:year => 2015, :month => 06, :range_type => :all_time)
          )
          result = stop_profiling('aggregate')
          expect(total_time(result)).to be_faster_than(:local => 0.1, :ci => 0.1)
        end
      end
    end
  end
end
