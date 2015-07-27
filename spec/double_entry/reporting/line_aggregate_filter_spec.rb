# encoding: utf-8
RSpec.describe DoubleEntry::Reporting::LineAggregateFilter do
  describe '.aggregate' do
    let(:function) { :sum }
    let(:account) { :account }
    let(:code) { :transfer_code }
    let(:named_scopes) do
      [
        :monkey_patched_method,
        { :monkey_patched_method_with_param => :parameter }
      ]
    end
    let(:start) { Time.parse('2014-07-27 10:55:44 +1000') }
    let(:finish) { Time.parse('2015-07-27 10:55:44 +1000') }
    let(:range) do
      instance_double(DoubleEntry::Reporting::MonthRange,
        :start => start,
        :finish => finish,
      )
    end

    let(:lines_scope) { spy(DoubleEntry::Line) }

    subject(:filter) do
      DoubleEntry::Reporting::LineAggregateFilter.new(
        account, code, range, named_scopes
      )
    end

    before do
      stub_const('DoubleEntry::Line', lines_scope)

      allow(lines_scope).to receive(:where).and_return(lines_scope)
      allow(lines_scope).to receive(:monkey_patched_method).and_return(lines_scope)
      allow(lines_scope).to receive(:monkey_patched_method_with_param).and_return(lines_scope)

      filter.aggregate
    end

    context 'with named scopes specified' do
      let(:named_scopes) do
        [
          :monkey_patched_method,
          { :monkey_patched_method_with_param => :parameter }
        ]
      end

      it 'filters by all the named scopes provided' do
        expect(DoubleEntry::Line).to have_received(:monkey_patched_method)
        expect(DoubleEntry::Line).to have_received(:monkey_patched_method_with_param).with(:parameter)
      end
    end

    context 'with a code specified' do
      let(:code) { :transfer_code }

      it 'retrieves the appropriate lines for aggregation' do
        expect(DoubleEntry::Line).to have_received(:where).with(:account => account)
        expect(DoubleEntry::Line).to have_received(:where).with(:created_at => start..finish)
        expect(DoubleEntry::Line).to have_received(:where).with(:code => code)
      end
    end

    context 'with no code specified' do
      let(:code) { nil }

      it 'retrieves the appropriate lines for aggregation' do
        expect(DoubleEntry::Line).to have_received(:where).with(:account => account)
        expect(DoubleEntry::Line).to have_received(:where).with(:created_at => start..finish)
      end
    end

  end
end
