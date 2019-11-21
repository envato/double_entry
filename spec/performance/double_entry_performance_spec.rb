module DoubleEntry
  RSpec.describe DoubleEntry do
    describe 'transfer performance' do
      include PerformanceHelper
      let(:user) { create(:user) }
      let(:amount) { Money.new(10_00) }
      let(:test) { DoubleEntry.account(:test, :scope => user) }
      let(:savings) { DoubleEntry.account(:savings, :scope => user) }

      it 'creates a lot of transfers quickly without metadata' do
        profile_transfers_with_metadata(nil)
        # local results: 6.44, 5.93, 5.94
      end

      it 'creates a lot of transfers quickly with metadata & separate metadata table' do
        big_metadata = {}
        8.times { |i| big_metadata["key#{i}".to_sym] = "value#{i}" }
        profile_transfers_with_metadata(big_metadata, 'transfer-with-metadata-table')
        # local results: 21.2, 21.6, 20.9
      end

      it 'creates a lot of transfers quickly with metadata & metadata column on lines table', skip: ActiveRecord.version.version < '5' do
        DoubleEntry.config.json_metadata = true
        big_metadata = {}
        8.times { |i| big_metadata["key#{i}".to_sym] = "value#{i}" }
        profile_transfers_with_metadata(big_metadata, 'transfer-with-metadata-column')
        DoubleEntry.config.json_metadata = false
        # local results: 21.2, 21.6, 20.9
      end
    end

    def profile_transfers_with_metadata(metadata, profile_name = nil)
      start_profiling
      options = { :from => test, :to => savings, :code => :bonus }
      options[:metadata] = metadata if metadata
      100.times { Transfer.transfer(amount, options) }
      profile_name ||= 'transfer'
      stop_profiling(profile_name)
    end
  end
end
