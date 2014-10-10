# encoding: utf-8
require 'spec_helper'
module DoubleEntry
  module Reporting
    describe Aggregate do

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
        Reporting.aggregate(:sum, :savings, :bonus,
                            :range => TimeRange.make(:year => 2009, :month => 10))
        expect(LineAggregate.count).to eq 1
      end

      it 'should only store the aggregate once if it is requested more than once' do
        Reporting.aggregate(:sum, :savings, :bonus,
                            :range => TimeRange.make(:year => 2009, :month => 9))
        Reporting.aggregate(:sum, :savings, :bonus,
                            :range => TimeRange.make(:year => 2009, :month => 9))
        Reporting.aggregate(:sum, :savings, :bonus,
                            :range => TimeRange.make(:year => 2009, :month => 10))
        expect(LineAggregate.count).to eq 2
      end

      it 'should calculate the complete year correctly' do
        expect(
          Reporting.aggregate(:sum, :savings, :bonus, :range => TimeRange.make(:year => 2009))
        ).to eq Money.new(200_00)
      end

      it 'should calculate seperate months correctly' do
        expect(
          Reporting.aggregate(:sum, :savings, :bonus, :range => TimeRange.make(:year => 2009, :month => 10))
        ).to eq Money.new(110_00)
        expect(
          Reporting.aggregate(:sum, :savings, :bonus, :range => TimeRange.make(:year => 2009, :month => 11))
        ).to eq Money.new(90_00)
      end

      it 'should calculate seperate weeks correctly' do
        # Week 40 - Mon Sep 28, 2009 to Sun Oct 4 2009
        expect(
          Reporting.aggregate(:sum, :savings, :bonus, :range => TimeRange.make(:year => 2009, :week => 40))
        ).to eq Money.new(60_00)
      end

      it 'should calculate seperate days correctly' do
        # 1 Nov 2009
        expect(
          Reporting.aggregate(:sum, :savings, :bonus, :range => TimeRange.make(:year => 2009, :week => 44, :day => 7))
        ).to eq Money.new(90_00)
      end

      it 'should calculate seperate hours correctly' do
        # 1 Nov 2009
        expect(
          Reporting.aggregate(:sum, :savings, :bonus, :range => TimeRange.make(:year => 2009, :week => 44, :day => 7, :hour => 0))
        ).to eq Money.new(40_00)
        expect(
          Reporting.aggregate(:sum, :savings, :bonus, :range => TimeRange.make(:year => 2009, :week => 44, :day => 7, :hour => 1))
        ).to eq Money.new(50_00)
      end

      it 'should calculate, but not store aggregates when the time range is still current' do
        Timecop.freeze Time.local(2009, 11, 21) do
          expect(
            Reporting.aggregate(:sum, :savings, :bonus, :range => TimeRange.make(:year => 2009, :month => 11))
          ).to eq Money.new(90_00)
          expect(LineAggregate.count).to eq 0
        end
      end

      it 'should calculate, but not store aggregates when the time range is in the future' do
        Timecop.freeze Time.local(2009, 11, 21) do
          expect(
            Reporting.aggregate(:sum, :savings, :bonus, :range => TimeRange.make(:year => 2009, :month => 12))
          ).to eq Money.new(0)
          expect(LineAggregate.count).to eq 0
        end
      end

      it 'should calculate monthly all_time ranges correctly' do
        expect(
          Reporting.aggregate(:sum, :savings, :bonus, :range => TimeRange.make(:year => 2009, :month => 12, :range_type => :all_time))
        ).to eq Money.new(200_00)
      end

      it 'calculates the average monthly all_time ranges correctly' do
        expect(
          Reporting.aggregate(:average, :savings, :bonus, :range => TimeRange.make(:year => 2009, :month => 12, :range_type => :all_time))
        ).to eq expected_monthly_average
      end

      it 'returns the correct count for weekly all_time ranges correctly' do
        expect(
          Reporting.aggregate(:count, :savings, :bonus, :range => TimeRange.make(:year => 2009, :month => 12, :range_type => :all_time))
        ).to eq 5
      end

      it 'should calculate weekly all_time ranges correctly' do
        expect(
          Reporting.aggregate(:sum, :savings, :bonus, :range => TimeRange.make(:year => 2009, :week => 43, :range_type => :all_time))
        ).to eq Money.new(110_00)
      end

      it 'calculates the average weekly all_time ranges correctly' do
        expect(
          Reporting.aggregate(:average, :savings, :bonus, :range => TimeRange.make(:year => 2009, :week => 43, :range_type => :all_time))
        ).to eq expected_weekly_average
      end

      it 'returns the correct count for weekly all_time ranges correctly' do
        expect(
          Reporting.aggregate(:count, :savings, :bonus, :range => TimeRange.make(:year => 2009, :week => 43, :range_type => :all_time))
        ).to eq 3
      end

      it "raises an AggregateFunctionNotSupported exception" do
        expect{
          Reporting.aggregate(:not_supported_calculation, :savings, :bonus, :range => TimeRange.make(:year => 2009, :week => 43, :range_type => :all_time))
        }.to raise_error(AggregateFunctionNotSupported)
      end

      context 'filters' do

        let(:range) { TimeRange.make(:year => 2011, :month => 10) }

        class ::DoubleEntry::Line
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
          expect {
            Reporting.aggregate(:sum, :savings, :bonus, :range => range, :filter => [:test_filter])
          }.to change { LineAggregate.count }.by 1
        end

        it 'saves filtered aggregation only once for a range' do
          expect {
            Reporting.aggregate(:sum, :savings, :bonus, :range => range, :filter => [:test_filter])
            Reporting.aggregate(:sum, :savings, :bonus, :range => range, :filter => [:test_filter])
          }.to change { LineAggregate.count }.by 1
        end

        it 'saves filtered aggregations and non filtered aggregations separately' do
          expect {
            Reporting.aggregate(:sum, :savings, :bonus, :range => range, :filter => [:test_filter])
            Reporting.aggregate(:sum, :savings, :bonus, :range => range)
          }.to change { LineAggregate.count }.by 2
        end

        it 'loads the correct saved aggregation' do

          # cache the results for filtered and unfiltered aggregations
          Reporting.aggregate(:sum, :savings, :bonus, :range => range, :filter => [:test_filter])
          Reporting.aggregate(:sum, :savings, :bonus, :range => range)

          # ensure a second call loads the correct cached value
          expect(
            Reporting.aggregate(:sum, :savings, :bonus, :range  => range, :filter => [:test_filter])
          ).to eq Money.new(10_00)
          expect(
            Reporting.aggregate(:sum, :savings, :bonus, :range  => range)
          ).to eq Money.new(19_00)
        end
      end
    end
    describe Aggregate, "currencies" do
      let(:user) { User.make! }
      before do
        perform_btc_deposit(user, 100_000_000)
        perform_btc_deposit(user, 200_000_000)
      end

      it 'should calculate the sum in the correct currency' do
        expect(
          Reporting.aggregate(:sum, :btc_savings, :btc_test_transfer, :range => TimeRange.make(:year => Time.now.year))
        ).to eq Money.new(300_000_000, :btc)
      end
    end
  end
end
