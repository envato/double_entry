module DoubleEntry
  RSpec.describe DoubleEntry do
    describe 'transfer performance' do
      include PerformanceHelper
      let(:user) { User.make! }

      it 'creates a lot of transfers quickly' do
        start_profiling
        # TODO: transfers with metadata
        1000.times { perform_deposit user, 1_00 }
        result = stop_profiling('transfers')
        expect(total_time(result)).to be_faster_than(:local => 65, :ci => 0)
      end
    end
  end
end
