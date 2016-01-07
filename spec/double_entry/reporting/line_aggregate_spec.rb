# encoding: utf-8
RSpec.describe DoubleEntry::Reporting::LineAggregate do
  describe '.table_name' do
    subject { DoubleEntry::Reporting::LineAggregate.table_name }
    it { should eq('double_entry_line_aggregates') }
  end

  describe '#aggregate' do
    let(:line_relation) { double }
    let(:filter) do
      instance_double(DoubleEntry::Reporting::LineAggregateFilter, :filter => line_relation)
    end

    let(:function) { :sum }
    let(:account) { double }
    let(:code) { double }
    let(:partner_account) { double }
    let(:named_scopes) { double }
    let(:range) { double }

    subject(:aggregate) do
      DoubleEntry::Reporting::LineAggregate.aggregate(
        function: function,
        account: account,
        partner_account: partner_account,
        code: code,
        range: range,
        named_scopes: named_scopes
      )
    end

    before do
      allow(DoubleEntry::Reporting::LineAggregateFilter).to receive(:new).and_return(filter)
      allow(line_relation).to receive(:sum).with(:amount)
      aggregate
    end

    it 'applies the specified filters' do
      expect(DoubleEntry::Reporting::LineAggregateFilter).to have_received(:new).
        with(account: account, partner_account: partner_account, code: code,
             range: range, filter_criteria: named_scopes)
      expect(filter).to have_received(:filter)
    end

    it 'performs the aggregation on the filtered lines' do
      expect(line_relation).to have_received(:sum).with(:amount)
    end
  end
end
