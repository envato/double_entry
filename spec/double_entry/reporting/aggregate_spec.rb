# encoding: utf-8
module DoubleEntry
  module Reporting
    RSpec.describe Aggregate do
      let(:user) { User.make! }
      let(:expected_weekly_average) do
        (Money.new(20_00) + Money.new(40_00) + Money.new(50_00)) / 3
      end
      let(:expected_monthly_average) do
        (Money.new(20_00) + Money.new(40_00) + Money.new(50_00) + Money.new(40_00) + Money.new(50_00)) / 5
      end

      before do
        # Thursday
        Timecop.freeze Time.local(2009, 10, 1) do
          perform_deposit(user, 20_00)
        end

        # Saturday
        Timecop.freeze Time.local(2009, 10, 3) do
          perform_deposit(user, 40_00)
        end

        Timecop.freeze Time.local(2009, 10, 10) do
          perform_deposit(user, 50_00)
        end

        Timecop.freeze Time.local(2009, 11, 1, 0, 59, 0) do
          perform_deposit(user, 40_00)
        end

        Timecop.freeze Time.local(2009, 11, 1, 1, 00, 0) do
          perform_deposit(user, 50_00)
        end

        allow(LineAggregate).to receive(:aggregate).and_call_original
      end

      it 'should store the aggregate for quick retrieval' do
        Aggregate.new(function: :sum, account: :savings, code: :bonus, range: TimeRange.make(:year => 2009, :month => 10)).amount
        expect(LineAggregate.count).to eq 1
      end

      describe 'partner_account aggregates' do
        context 'when transfers exist with the same account and code, but different partner_account' do
          before do
            Timecop.freeze Time.local(2009, 10, 1) do
              transfer_deposit_fee(user, 1_00)
              transfer_account_fee(user, 1_00)
            end

            Timecop.freeze Time.local(2009, 10, 5) do
              transfer_deposit_fee(user, 1_00)
            end

            Timecop.freeze Time.local(2009, 11, 1) do
              transfer_deposit_fee(user, 2_00)
              transfer_account_fee(user, 1_00)
            end
          end

          context 'when the partner_account is supplied' do
            it 'calculates the complete year correctly for deposit fees' do
              amount = Aggregate.new(function: :sum, account: :savings, code: :fee, range: TimeRange.make(:year => 2009), partner_account: :deposit_fees).formatted_amount
              expect(amount).to eq (Money.new(-4_00))
            end

            it 'calculates the complete year correctly for account fees' do
              amount = Aggregate.new(function: :sum, account: :savings, code: :fee, range: TimeRange.make(:year => 2009), partner_account: :account_fees).formatted_amount
              expect(amount).to eq (Money.new(-2_00))
            end
          end

          context 'when the partner_account is not supplied' do
            it 'calculates the complete year correctly for all fees' do
              amount = Aggregate.new(function: :sum, account: :savings, code: :fee, range: TimeRange.make(:year => 2009)).formatted_amount
              expect(amount).to eq (Money.new(-6_00))
            end
          end
        end

        it 'calculates a new aggregate when partner_account is specified' do
          Aggregate.new(function: :sum, account: :savings, code: :bonus, range: TimeRange.make(:year => 2009, :month => 9)).amount
          Aggregate.new(function: :sum, account: :savings, code: :bonus, range: TimeRange.make(:year => 2009, :month => 9), partner_account: :test).amount
          Aggregate.new(function: :sum, account: :savings, code: :bonus, range: TimeRange.make(:year => 2009, :month => 10)).amount
          expect(LineAggregate.count).to eq 3
          expect(LineAggregate).to have_received(:aggregate).exactly(3).times
        end

        it "only stores an aggregate including partner_account once if it's requested more than once" do
          Aggregate.new(function: :sum, account: :savings, code: :bonus, range: TimeRange.make(:year => 2009, :month => 9), partner_account: :test).amount
          Aggregate.new(function: :sum, account: :savings, code: :bonus, range: TimeRange.make(:year => 2009, :month => 9), partner_account: :test).amount
          Aggregate.new(function: :sum, account: :savings, code: :bonus, range: TimeRange.make(:year => 2009, :month => 10), partner_account: :test).amount
          expect(LineAggregate.count).to eq 2
          expect(LineAggregate).to have_received(:aggregate).twice
        end
      end

      it 'only stores the aggregate once if it is requested more than once' do
        Aggregate.new(function: :sum, account: :savings, code: :bonus, range: TimeRange.make(:year => 2009, :month => 9)).amount
        Aggregate.new(function: :sum, account: :savings, code: :bonus, range: TimeRange.make(:year => 2009, :month => 9)).amount
        Aggregate.new(function: :sum, account: :savings, code: :bonus, range: TimeRange.make(:year => 2009, :month => 10)).amount
      end

      it 'should only store the aggregate once if it is requested more than once' do
        Aggregate.new(function: :sum, account: :savings, code: :bonus, range: TimeRange.make(:year => 2009, :month => 9)).amount
        Aggregate.new(function: :sum, account: :savings, code: :bonus, range: TimeRange.make(:year => 2009, :month => 9)).amount
        Aggregate.new(function: :sum, account: :savings, code: :bonus, range: TimeRange.make(:year => 2009, :month => 10)).amount
        expect(LineAggregate.count).to eq 2
        expect(LineAggregate).to have_received(:aggregate).twice
      end

      it 'calculates the complete year correctly' do
        amount = Aggregate.new(function: :sum, account: :savings, code: :bonus, range: TimeRange.make(:year => 2009)).formatted_amount
        expect(amount).to eq Money.new(200_00)
      end

      it 'calculates seperate months correctly' do
        amount = Aggregate.new(function: :sum, account: :savings, code: :bonus, range: TimeRange.make(:year => 2009, :month => 10)).formatted_amount
        expect(amount).to eq Money.new(110_00)

        amount = Aggregate.new(function: :sum, account: :savings, code: :bonus, range: TimeRange.make(:year => 2009, :month => 11)).formatted_amount
        expect(amount).to eq Money.new(90_00)
      end

      it 'calculates separate weeks correctly' do
        # Week 40 - Mon Sep 28, 2009 to Sun Oct 4 2009
        amount = Aggregate.new(function: :sum, account: :savings, code: :bonus, range: TimeRange.make(:year => 2009, :week => 40)).formatted_amount
        expect(amount).to eq Money.new(60_00)
      end

      it 'calculates separate days correctly' do
        # 1 Nov 2009
        amount = Aggregate.new(function: :sum, account: :savings, code: :bonus, range: TimeRange.make(:year => 2009, :week => 44, :day => 7)).formatted_amount
        expect(amount).to eq Money.new(90_00)
      end

      it 'calculates separate hours correctly' do
        # 1 Nov 2009
        amount = Aggregate.new(function: :sum, account: :savings, code: :bonus, range: TimeRange.make(:year => 2009, :week => 44, :day => 7, :hour => 0)).formatted_amount
        expect(amount).to eq Money.new(40_00)
        amount = Aggregate.new(function: :sum, account: :savings, code: :bonus, range: TimeRange.make(:year => 2009, :week => 44, :day => 7, :hour => 1)).formatted_amount
        expect(amount).to eq Money.new(50_00)
      end

      it 'calculates, but not store aggregates when the time range is still current' do
        Timecop.freeze Time.local(2009, 11, 21) do
          amount = Aggregate.new(function: :sum, account: :savings, code: :bonus, range: TimeRange.make(:year => 2009, :month => 11)).formatted_amount
          expect(amount).to eq Money.new(90_00)
          expect(LineAggregate.count).to eq 0
        end
      end

      it 'calculates, but not store aggregates when the time range is in the future' do
        Timecop.freeze Time.local(2009, 11, 21) do
          amount = Aggregate.new(function: :sum, account: :savings, code: :bonus, range: TimeRange.make(:year => 2009, :month => 12)).formatted_amount
          expect(amount).to eq Money.new(0)
          expect(LineAggregate.count).to eq 0
        end
      end

      it 'calculates monthly all_time ranges correctly' do
        amount = Aggregate.new(function: :sum, account: :savings, code: :bonus, range: TimeRange.make(:year => 2009, :month => 12, :range_type => :all_time)).formatted_amount
        expect(amount).to eq Money.new(200_00)
      end

      it 'calculates the average monthly all_time ranges correctly' do
        amount = Aggregate.new(function: :average, account: :savings, code: :bonus, range: TimeRange.make(:year => 2009, :month => 12, :range_type => :all_time)).formatted_amount
        expect(amount).to eq expected_monthly_average
      end

      it 'returns the correct count for weekly all_time ranges correctly' do
        amount = Aggregate.new(function: :count, account: :savings, code: :bonus, range: TimeRange.make(:year => 2009, :month => 12, :range_type => :all_time)).formatted_amount
        expect(amount).to eq 5
      end

      it 'calculates weekly all_time ranges correctly' do
        amount = Aggregate.new(function: :sum, account: :savings, code: :bonus, range: TimeRange.make(:year => 2009, :week => 43, :range_type => :all_time)).formatted_amount
        expect(amount).to eq Money.new(110_00)
      end

      it 'calculates the average weekly all_time ranges correctly' do
        amount = Aggregate.new(function: :average, account: :savings, code: :bonus, range: TimeRange.make(:year => 2009, :week => 43, :range_type => :all_time)).formatted_amount
        expect(amount).to eq expected_weekly_average
      end

      it 'returns the correct count for weekly all_time ranges correctly' do
        amount = Aggregate.new(function: :count, account: :savings, code: :bonus, range: TimeRange.make(:year => 2009, :week => 43, :range_type => :all_time)).formatted_amount
        expect(amount).to eq 3
      end

      it 'raises an AggregateFunctionNotSupported exception' do
        expect do
          Aggregate.new(function:
            :not_supported_calculation,account:  :savings, code: :bonus, range: TimeRange.make(:year => 2009, :week => 43, :range_type => :all_time)
          ).amount
        end.to raise_error(AggregateFunctionNotSupported)
      end

      context 'filters' do
        let(:range) { TimeRange.make(:year => 2011, :month => 10) }
        let(:filter) do
          [
            :scope => {
              :name => :test_filter,
            },
          ]
        end

        DoubleEntry::Line.class_eval do
          scope :test_filter, -> { where(:amount => 10_00) }
        end

        before do
          Timecop.freeze Time.local(2011, 10, 10) do
            perform_deposit user, 10_00
          end

          Timecop.freeze Time.local(2011, 10, 10) do
            perform_deposit user, 9_00
          end
        end

        it 'saves filtered aggregations' do
          expect do
            Aggregate.new(function: :sum, account: :savings, code: :bonus, range: range, :filter => filter).amount
          end.to change { LineAggregate.count }.by 1
        end

        it 'saves filtered aggregation only once for a range' do
          expect do
            Aggregate.new(function: :sum, account: :savings, code: :bonus, range: range, :filter => filter).amount
            Aggregate.new(function: :sum, account: :savings, code: :bonus, range: range, :filter => filter).amount
          end.to change { LineAggregate.count }.by 1
        end

        it 'saves filtered aggregations and non filtered aggregations separately' do
          expect do
            Aggregate.new(function: :sum, account: :savings, code: :bonus, range: range, :filter => filter).amount
            Aggregate.new(function: :sum, account: :savings, code: :bonus, range: range).amount
          end.to change { LineAggregate.count }.by 2
        end

        it 'loads the correct saved aggregation' do
          # cache the results for filtered and unfiltered aggregations
          Aggregate.new(function: :sum, account: :savings, code: :bonus, range: range, :filter => filter).amount
          Aggregate.new(function: :sum, account: :savings, code: :bonus, range: range).amount

          # ensure a second call loads the correct cached value
          amount = Aggregate.new(function: :sum, account: :savings, code: :bonus, range: range, :filter => filter).formatted_amount
          expect(amount).to eq Money.new(10_00)

          amount = Aggregate.new(function: :sum, account: :savings, code: :bonus, range: range).formatted_amount
          expect(amount).to eq Money.new(19_00)
        end
      end
    end
    RSpec.describe Aggregate, 'currencies' do
      let(:user) { User.make! }
      before do
        perform_btc_deposit(user, 100_000_000)
        perform_btc_deposit(user, 200_000_000)
      end

      it 'calculates the sum in the correct currency' do
        amount = Aggregate.new(function: :sum, account: :btc_savings, code: :btc_test_transfer, range: TimeRange.make(:year => Time.now.year)).formatted_amount
        expect(amount).to eq(Money.new(300_000_000, :btc))
      end
    end
  end
end
