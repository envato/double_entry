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
          perform_deposit user, 20_00
        end

        # Saturday
        Timecop.freeze Time.local(2009, 10, 3) do
          perform_deposit user, 40_00
        end

        Timecop.freeze Time.local(2009, 10, 10) do
          perform_deposit user, 50_00
        end
        Timecop.freeze Time.local(2009, 11, 1, 0, 59, 0) do
          perform_deposit user, 40_00
        end
        Timecop.freeze Time.local(2009, 11, 1, 1, 00, 0) do
          perform_deposit user, 50_00
        end
      end

      it 'should store the aggregate for quick retrieval' do
        Aggregate.new(:sum, :savings, :bonus, :range => TimeRange.make(:year => 2009, :month => 10)).amount
        expect(LineAggregate.count).to eq 1
      end

      it 'should only store the aggregate once if it is requested more than once' do
        Aggregate.new(:sum, :savings, :bonus, :range => TimeRange.make(:year => 2009, :month => 9)).amount
        Aggregate.new(:sum, :savings, :bonus, :range => TimeRange.make(:year => 2009, :month => 9)).amount
        Aggregate.new(:sum, :savings, :bonus, :range => TimeRange.make(:year => 2009, :month => 10)).amount
        expect(LineAggregate.count).to eq 2
      end

      it 'should calculate the complete year correctly' do
        expect(
          Aggregate.new(
            :sum, :savings, :bonus,
            :range => TimeRange.make(:year => 2009)
          ).formatted_amount,
        ).to eq Money.new(200_00)
      end

      it 'should calculate seperate months correctly' do
        expect(
          Aggregate.new(
            :sum, :savings, :bonus,
            :range => TimeRange.make(:year => 2009, :month => 10)
          ).formatted_amount,
        ).to eq Money.new(110_00)
        expect(
          Aggregate.new(
            :sum, :savings, :bonus,
            :range => TimeRange.make(:year => 2009, :month => 11)
          ).formatted_amount,
        ).to eq Money.new(90_00)
      end

      it 'should calculate seperate weeks correctly' do
        # Week 40 - Mon Sep 28, 2009 to Sun Oct 4 2009
        expect(
          Aggregate.new(
            :sum, :savings, :bonus,
            :range => TimeRange.make(:year => 2009, :week => 40)
          ).formatted_amount,
        ).to eq Money.new(60_00)
      end

      it 'should calculate seperate days correctly' do
        # 1 Nov 2009
        expect(
          Aggregate.new(
            :sum, :savings, :bonus,
            :range => TimeRange.make(:year => 2009, :week => 44, :day => 7)
          ).formatted_amount,
        ).to eq Money.new(90_00)
      end

      it 'should calculate seperate hours correctly' do
        # 1 Nov 2009
        expect(
          Aggregate.new(
            :sum, :savings, :bonus,
            :range => TimeRange.make(:year => 2009, :week => 44, :day => 7, :hour => 0)
          ).formatted_amount,
        ).to eq Money.new(40_00)
        expect(
          Aggregate.new(
            :sum, :savings, :bonus,
            :range => TimeRange.make(:year => 2009, :week => 44, :day => 7, :hour => 1)
          ).formatted_amount,
        ).to eq Money.new(50_00)
      end

      it 'should calculate, but not store aggregates when the time range is still current' do
        Timecop.freeze Time.local(2009, 11, 21) do
          expect(
            Aggregate.new(
              :sum, :savings, :bonus,
              :range => TimeRange.make(:year => 2009, :month => 11)
            ).formatted_amount,
          ).to eq Money.new(90_00)
          expect(LineAggregate.count).to eq 0
        end
      end

      it 'should calculate, but not store aggregates when the time range is in the future' do
        Timecop.freeze Time.local(2009, 11, 21) do
          expect(
            Aggregate.new(
              :sum, :savings, :bonus,
              :range => TimeRange.make(:year => 2009, :month => 12)
            ).formatted_amount,
          ).to eq Money.new(0)
          expect(LineAggregate.count).to eq 0
        end
      end

      it 'should calculate monthly all_time ranges correctly' do
        expect(
          Aggregate.new(
            :sum, :savings, :bonus,
            :range => TimeRange.make(:year => 2009, :month => 12, :range_type => :all_time)
          ).formatted_amount,
        ).to eq Money.new(200_00)
      end

      it 'calculates the average monthly all_time ranges correctly' do
        expect(
          Aggregate.new(
            :average, :savings, :bonus,
            :range => TimeRange.make(:year => 2009, :month => 12, :range_type => :all_time)
          ).formatted_amount,
        ).to eq expected_monthly_average
      end

      it 'returns the correct count for weekly all_time ranges correctly' do
        expect(
          Aggregate.new(
            :count, :savings, :bonus,
            :range => TimeRange.make(:year => 2009, :month => 12, :range_type => :all_time)
          ).formatted_amount,
        ).to eq 5
      end

      it 'should calculate weekly all_time ranges correctly' do
        expect(
          Aggregate.new(
            :sum, :savings, :bonus,
            :range => TimeRange.make(:year => 2009, :week => 43, :range_type => :all_time)
          ).formatted_amount,
        ).to eq Money.new(110_00)
      end

      it 'calculates the average weekly all_time ranges correctly' do
        expect(
          Aggregate.new(
            :average, :savings, :bonus,
            :range => TimeRange.make(:year => 2009, :week => 43, :range_type => :all_time)
          ).formatted_amount,
        ).to eq expected_weekly_average
      end

      it 'returns the correct count for weekly all_time ranges correctly' do
        expect(
          Aggregate.new(
            :count, :savings, :bonus,
            :range => TimeRange.make(:year => 2009, :week => 43, :range_type => :all_time)
          ).formatted_amount,
        ).to eq 3
      end

      it 'raises an AggregateFunctionNotSupported exception' do
        expect do
          Aggregate.new(
            :not_supported_calculation, :savings, :bonus,
            :range => TimeRange.make(:year => 2009, :week => 43, :range_type => :all_time)
          ).amount
        end.to raise_error(AggregateFunctionNotSupported)
      end

      context 'filters' do
        let(:range) { TimeRange.make(:year => 2011, :month => 10) }

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
            Aggregate.new(:sum, :savings, :bonus, :range => range, :filter => [:test_filter]).amount
          end.to change { LineAggregate.count }.by 1
        end

        it 'saves filtered aggregation only once for a range' do
          expect do
            Aggregate.new(:sum, :savings, :bonus, :range => range, :filter => [:test_filter]).amount
            Aggregate.new(:sum, :savings, :bonus, :range => range, :filter => [:test_filter]).amount
          end.to change { LineAggregate.count }.by 1
        end

        it 'saves filtered aggregations and non filtered aggregations separately' do
          expect do
            Aggregate.new(:sum, :savings, :bonus, :range => range, :filter => [:test_filter]).amount
            Aggregate.new(:sum, :savings, :bonus, :range => range).amount
          end.to change { LineAggregate.count }.by 2
        end

        it 'loads the correct saved aggregation' do
          # cache the results for filtered and unfiltered aggregations
          Aggregate.new(:sum, :savings, :bonus, :range => range, :filter => [:test_filter]).amount
          Aggregate.new(:sum, :savings, :bonus, :range => range).amount

          # ensure a second call loads the correct cached value
          expect(
            Aggregate.new(:sum, :savings, :bonus, :range  => range, :filter => [:test_filter]).formatted_amount,
          ).to eq Money.new(10_00)
          expect(
            Aggregate.new(:sum, :savings, :bonus, :range  => range).formatted_amount,
          ).to eq Money.new(19_00)
        end
      end
    end
    RSpec.describe Aggregate, 'currencies' do
      let(:user) { User.make! }
      before do
        perform_btc_deposit(user, 100_000_000)
        perform_btc_deposit(user, 200_000_000)
      end

      it 'should calculate the sum in the correct currency' do
        expect(
          Aggregate.new(
            :sum, :btc_savings, :btc_test_transfer, :range => TimeRange.make(:year => Time.now.year)
          ).formatted_amount,
        ).to eq(Money.new(300_000_000, :btc))
      end
    end
  end
end
