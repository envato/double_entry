module DoubleEntry
  module Reporting
    RSpec.describe AggregateArray do
      let(:user) { create(:user) }
      let(:start) { nil }
      let(:finish) { nil }
      let(:range_type) { 'year' }
      let(:function) { 'sum' }
      let(:account) { :savings }
      let(:transfer_code) { :bonus }
      subject(:aggregate_array) do
        AggregateArray.new(
          function: function,
          account: account,
          code: transfer_code,
          range_type: range_type,
          start: start,
          finish: finish,
        )
      end

      context 'given a deposit was made in 2007 and 2008' do
        before do
          Timecop.travel(Time.local(2007)) do
            perform_deposit user, 10_00
          end
          Timecop.travel(Time.local(2008)) do
            perform_deposit user, 20_00
          end
        end

        context 'given the date is 2009-03-19' do
          before { Timecop.travel(Time.local(2009, 3, 19)) }

          context 'when called with range type of "year"' do
            let(:range_type) { 'year' }
            let(:start) { '2006-08-03' }
            it { should eq [Money.zero, Money.new(10_00), Money.new(20_00), Money.zero] }

            describe 'reuse of aggregates' do
              let(:years) { TimeRangeArray.make(range_type, start, finish) }

              context 'and some aggregates were created previously' do
                before do
                  Aggregate.formatted_amount(function: function, account: account, code: transfer_code, range: years[0])
                  Aggregate.formatted_amount(function: function, account: account, code: transfer_code, range: years[1])
                  allow(Aggregate).to receive(:formatted_amount)
                end

                context 'and the transfer code is not provided' do
                  let(:transfer_code) { nil }

                  it 'only asks Aggregate for the non-existent ones' do
                    expect(Aggregate).not_to receive(:formatted_amount).
                      with(function: function, account: account, code: transfer_code,
                           range: years[0], partner_account: nil, filter: nil)
                    expect(Aggregate).not_to receive(:formatted_amount).
                      with(function: function, account: account, code: transfer_code,
                           range: years[1], partner_account: nil, filter: nil)

                    expect(Aggregate).to receive(:formatted_amount).
                      with(function: function, account: account, code: transfer_code,
                           range: years[2], partner_account: nil, filter: nil)
                    expect(Aggregate).to receive(:formatted_amount).
                      with(function: function, account: account, code: transfer_code,
                           range: years[3], partner_account: nil, filter: nil)
                    aggregate_array
                  end

                  context 'and the transfer code is provided' do
                    let(:transfer_code) { :bonus }

                    it 'only asks Aggregate for the non-existent ones' do
                      expect(Aggregate).not_to receive(:formatted_amount).
                        with(function: function, account: account, code: transfer_code,
                             range: years[0], partner_account: nil, filter: nil)
                      expect(Aggregate).not_to receive(:formatted_amount).
                        with(function: function, account: account, code: transfer_code,
                             range: years[1], partner_account: nil, filter: nil)

                      expect(Aggregate).to receive(:formatted_amount).
                        with(function: function, account: account, code: transfer_code,
                             range: years[2], partner_account: nil, filter: nil)
                      expect(Aggregate).to receive(:formatted_amount).
                        with(function: function, account: account, code: transfer_code,
                             range: years[3], partner_account: nil, filter: nil)
                      aggregate_array
                    end
                  end
                end
              end
            end
          end
        end
      end

      context 'given a deposit was made in October and December 2006' do
        before do
          Timecop.travel(Time.local(2006, 10)) do
            perform_deposit user, 10_00
          end
          Timecop.travel(Time.local(2006, 12)) do
            perform_deposit user, 20_00
          end
        end

        context 'when called with range type of "month", a start of "2006-09-01", and finish of "2007-01-02"' do
          let(:range_type) { 'month' }
          let(:start) { '2006-09-01' }
          let(:finish) { '2007-01-02' }
          it { should eq [Money.zero, Money.new(10_00), Money.zero, Money.new(20_00), Money.zero] }
        end

        context 'given the date is 2007-02-02' do
          before { Timecop.travel(Time.local(2007, 2, 2)) }

          context 'when called with range type of "month"' do
            let(:range_type) { 'month' }
            let(:start) { '2006-08-03' }
            it { should eq [Money.zero, Money.zero, Money.new(10_00), Money.zero, Money.new(20_00), Money.zero, Money.zero] }
          end
        end
      end

      context 'when account is in BTC currency' do
        let(:account) { :btc_savings }
        let(:range_type) { 'year' }
        let(:start) { "#{Time.now.year}-01-01" }
        let(:transfer_code) { :btc_test_transfer }

        before do
          perform_btc_deposit(user, 100_000_000)
          perform_btc_deposit(user, 100_000_000)
        end

        it { should eq [Money.new(200_000_000, :btc)] }
      end

      context 'when called with range type of "invalid_and_should_not_work"' do
        let(:range_type) { 'invalid_and_should_not_work' }
        it 'raises an argument error' do
          expect { aggregate_array }.to raise_error ArgumentError, "Invalid range type 'invalid_and_should_not_work'"
        end
      end

      context 'when an invalid function is provided' do
        let(:range_type) { 'month' }
        let(:start) { '2006-08-03' }
        let(:function) { :invalid_function }
        it 'raises an AggregateFunctionNotSupported error' do
          expect { aggregate_array }.to raise_error AggregateFunctionNotSupported
        end
      end
    end
  end
end
