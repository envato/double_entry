# encoding: utf-8
RSpec.describe DoubleEntry::Reporting::LineAggregateFilter do
  describe '.filter' do
    let(:function) { :sum }
    let(:account) { :account }
    let(:code) { :transfer_code }
    let(:filter_criteria) { nil }
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
        account, code, range, filter_criteria
      )
    end

    before do
      stub_const('DoubleEntry::Line', lines_scope)

      allow(lines_scope).to receive(:where).and_return(lines_scope)
      allow(lines_scope).to receive(:joins).and_return(lines_scope)
      allow(lines_scope).to receive(:ten_dollar_purchases).and_return(lines_scope)
      allow(lines_scope).to receive(:ten_dollar_purchases_by_category).and_return(lines_scope)

      filter.filter
    end

    context 'with named scopes specified' do
      let(:filter_criteria) do
        [
          # an example of calling a named scope called with arguments
          {
            :scope => {
              :name => :ten_dollar_purchases_by_category,
              :arguments => [:cat_videos, :cat_pictures]
            }
          },
          # an example of calling a named scope with no arguments
          {
            :scope => {
              :name => :ten_dollar_purchases
            }
          },
          # an example of providing metadata criteria to filter on
          {
            :metadata => {
              :meme => :business_cat,
              :attire => :business
            }
          }
        ]
      end

      it 'filters by all the scopes provided' do
        expect(DoubleEntry::Line).to have_received(:ten_dollar_purchases)
        expect(DoubleEntry::Line).to have_received(:ten_dollar_purchases_by_category).
          with(:cat_videos, :cat_pictures)
      end

      it 'filters by all the metadata provided' do
        expect(DoubleEntry::Line).to have_received(:joins).with(:metadata)
        expect(DoubleEntry::Line).to have_received(:where).
          with(:key => :meme, :value => :business_cat)
        expect(DoubleEntry::Line).to have_received(:where).
          with(:key => :attire, :value => :business)
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
