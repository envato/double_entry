# encoding: utf-8
RSpec.describe DoubleEntry::Reporting::LineMetadataFilter do
  describe '.filter' do
    let(:collection) { DoubleEntry::Line }
    let(:metadata) {
      {
        :meme  => 'business_cat',
        :genre => 'comedy',
      }
    }

    subject(:filter) { DoubleEntry::Reporting::LineMetadataFilter.filter(collection: collection, metadata: metadata) }

    before do
      allow(collection).to receive(:joins).and_return(collection)
      allow(collection).to receive(:where).and_return(collection)
      allow(DoubleEntry::LineMetadata).to receive(:table_name).and_return('double_entry_line_metadata')
      allow(DoubleEntry::Line).to receive(:table_name).and_return('double_entry_lines')
      filter
    end

    it 'queries for matches to the first key value pair' do
      expect(collection).to have_received(:joins).
        with('INNER JOIN double_entry_line_metadata as m0 ON m0.line_id = double_entry_lines.id')
      expect(collection).to have_received(:where).
        with('m0.key = ? AND m0.value = ?', :meme, 'business_cat')
    end

    it 'queries for matches to the second key value pair' do
      expect(collection).to have_received(:joins).
       with('INNER JOIN double_entry_line_metadata as m1 ON m1.line_id = double_entry_lines.id')
      expect(collection).to have_received(:where).
        with('m1.key = ? AND m1.value = ?', :genre, 'comedy')
    end
  end
end
