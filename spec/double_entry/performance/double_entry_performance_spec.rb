module DoubleEntry
  RSpec.describe DoubleEntry do
    describe 'transfer performance' do
      include PerformanceHelper
      let(:user) { User.make! }
      let(:amount) { Money.new(10_00) }
      let(:test) { DoubleEntry.account(:test, :scope => user) }
      let(:savings) { DoubleEntry.account(:savings, :scope => user) }

      it 'creates a lot of transfers quickly' do
        no_metadata_time = profile_transfers_with_metadata(nil)
        big_metadata = {}
        num_pairs = 8
        num_pairs.times { |i| big_metadata["key#{i}".to_sym] = "value#{i}" }
        metadata_time = profile_transfers_with_metadata(big_metadata)

        time_per_pair = (metadata_time - no_metadata_time) / num_pairs

        expect(no_metadata_time).to be_faster_than(:local => 6.5, :ci => 11)
        expect(time_per_pair).to be < 2
      end
    end

    def profile_transfers_with_metadata(metadata)
      start_profiling
      options = { :from => test, :to => savings, :code => :bonus }
      options[:metadata] = metadata if metadata
      100.times { Transfer.transfer(amount, options) }
      profile_name = metadata ? 'transfer-with-metadata' : 'transfer'
      total_time(stop_profiling(profile_name))
    end
  end
end
