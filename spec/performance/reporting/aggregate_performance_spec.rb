module DoubleEntry
  module Reporting
    RSpec.describe Aggregate do
      include PerformanceHelper
      let(:user) { create(:user) }
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

        it 'calculates monthly all_time ranges quickly without a filter' do
          profile_aggregation_with_filter(nil)
          # local results: 517ms, 484ms, 505ms, 482ms, 525ms
        end

        it 'calculates monthly all_time ranges quickly with a filter' do
          profile_aggregation_with_filter([:metadata => { :country => 'AU' }])
          # local results when run independently (caching improves performance when run consecutively):
          # 655ms, 613ms, 597ms, 607ms, 627ms
        end
      end

      def profile_aggregation_with_filter(filter)
        start_profiling
        range = TimeRange.make(:year   => 2015, :month => 06, :range_type => :all_time)
        Reporting.aggregate(function: :sum, account: :savings, code: :bonus, range: range, filter: filter)
        profile_name = filter ? 'aggregate-with-metadata' : 'aggregate'
        stop_profiling(profile_name)
      end
    end
  end
end
