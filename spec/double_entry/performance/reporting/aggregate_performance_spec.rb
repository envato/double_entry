module DoubleEntry
  module Reporting
    RSpec.describe Aggregate do
      include PerformanceHelper
      let(:user) { User.make! }

      context '1000 transfers in a single day' do
        # Surprisingly, the number of transfers makes no difference to the time taken to aggregate them. Some sample results:
        # 20,000 => 524ms
        # 10,000 => 573ms
        # 1,000  => 486ms
        # 100    => 608ms
        # 10     => 509ms
        # 1      => 473ms
        before do
          Timecop.freeze Time.local(2015, 06, 30) do
            1000.times { perform_deposit user, 1_00 }
            # TODO: perform_deposit_with_metadata
          end
        end

        it 'calculates monthly all_time ranges quickly' do
          start_profiling
          # TODO: aggregate with metadata filter
          Reporting.aggregate(
            :sum, :savings, :bonus, TimeRange.make(:year => 2015, :month => 06, :range_type => :all_time)
          )
          result = stop_profiling('aggregate')
          expect(total_time(result)).to be_faster_than(:local => 0.610, :ci => 0.800)
        end
      end
    end
  end
end
