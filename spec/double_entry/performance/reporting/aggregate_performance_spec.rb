module DoubleEntry
  module Reporting
    RSpec.describe Aggregate do
      include PerformanceHelper
      let(:user) { User.make! }
      let(:amount) { Money.new(10_00) }
      let(:test) { DoubleEntry.account(:test, :scope => user) }
      let(:savings) { DoubleEntry.account(:savings, :scope => user) }

      subject(:transfer) { Transfer.transfer(amount, options) }

      context '200 transfers in a single day, half with metadata' do
        # Surprisingly, the number of transfers makes no difference to the time taken to aggregate them. Some sample results:
        # 20,000 => 524ms
        # 10,000 => 573ms
        # 1,000  => 486ms
        # 100    => 608ms
        # 10     => 509ms
        # 1      => 473ms
        before do
          Timecop.freeze Time.local(2015, 06, 30) do
            100.times { Transfer.transfer(amount, :from => test, :to => savings, :code => :bonus) }
            100.times { Transfer.transfer(amount, :from => test, :to => savings, :code => :bonus, :metadata => { :country => 'AU', :tax => 'GST' }) }
          end
        end

        it 'calculates monthly all_time ranges quickly' do
          start_profiling
          # TODO: aggregate with metadata filter
          Reporting.aggregate(
            :sum, :savings, :bonus,
            :range => TimeRange.make(:year => 2015, :month => 06, :range_type => :all_time)
          )
          result = stop_profiling('aggregate')
          expect(total_time(result)).to be_faster_than(:local => 0.610, :ci => 0.800)
        end
      end

      def profile_aggregation_with_filter(filter)
        start_profiling
        options = { :range => TimeRange.make(:year   => 2015, :month => 06, :range_type => :all_time) }
        options[:filter] = filter if filter
        Reporting.aggregate(:sum, :savings, :bonus, options)
        profile_name = filter ? 'aggregate-with-metadata' : 'aggregate'
        total_time(stop_profiling(profile_name))
      end

      def clear_aggregate_cache
        DoubleEntry::Reporting::LineAggregate.delete_all
      end
    end
  end
end
