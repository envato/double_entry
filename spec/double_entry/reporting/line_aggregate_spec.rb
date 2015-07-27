# encoding: utf-8
RSpec.describe DoubleEntry::Reporting::LineAggregate do
  describe '.table_name' do
    subject { DoubleEntry::Reporting::LineAggregate.table_name }
    it { should eq('double_entry_line_aggregates') }
  end

  describe '#aggregate' do
    let(:filter) do
      instance_double(DoubleEntry::Reporting::LineAggregateFilter,
        :filter => line_relation
      )
    end
    let(:line_relation) do
      instance_double(DoubleEntry::Line::ActiveRecord_Relation,
        :sum => spy
      )
    end

    let(:function) { :sum }
    let(:account) { spy }
    let(:code) { spy }
    let(:named_scopes) { spy }
    let(:range) { spy }

    subject(:aggregate) do
      DoubleEntry::Reporting::LineAggregate.aggregate(
        function, account, code, range, named_scopes
      )
    end

    before do
      allow(DoubleEntry::Reporting::LineAggregateFilter).to receive(:new).and_return(filter)
      aggregate
    end

    it 'applies the specified filters' do
      expect(DoubleEntry::Reporting::LineAggregateFilter).to have_received(:new).
        with(account, code, range, named_scopes)
      expect(filter).to have_received(:filter)
    end

    it 'performs the aggregation on the filtered lines' do
      expect(line_relation).to have_received(:sum).with(:amount)
    end

  end
end
