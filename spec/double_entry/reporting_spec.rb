# encoding: utf-8
RSpec.describe DoubleEntry::Reporting do
  describe 'configuration' do
    describe 'start_of_business' do
      subject(:start_of_business) { DoubleEntry::Reporting.configuration.start_of_business }

      context 'configured to 2011-03-12' do
        before do
          DoubleEntry::Reporting.configure do |config|
            config.start_of_business = Time.new(2011, 3, 12)
          end
        end

        it { should eq Time.new(2011, 3, 12) }
      end

      context 'not configured' do
        it { should eq Time.new(1970, 1, 1) }
      end
    end
  end

  describe '.scopes_with_minimum_balance_for_account' do
    subject(:scopes) { DoubleEntry::Reporting.scopes_with_minimum_balance_for_account(minimum_balance, :checking) }

    context "a 'checking' account with balance $100" do
      let!(:user) { User.make!(:checking_balance => Money.new(100_00)) }

      context 'when searching for balance $99' do
        let(:minimum_balance) { Money.new(99_00) }
        it { should include user.id }
      end

      context 'when searching for balance $100' do
        let(:minimum_balance) { Money.new(100_00) }
        it { should include user.id }
      end

      context 'when searching for balance $101' do
        let(:minimum_balance) { Money.new(101_00) }
        it { should_not include user.id }
      end
    end
  end

  describe '.aggregate' do
    before do
      # get rid of "helpful" predefined config
      @config_accounts  = DoubleEntry.configuration.accounts
      @config_transfers = DoubleEntry.configuration.transfers
      DoubleEntry.configuration.accounts  = DoubleEntry::Account::Set.new
      DoubleEntry.configuration.transfers = DoubleEntry::Transfer::Set.new

      DoubleEntry.configure do |config|
        config.define_accounts do |accounts|
          accounts.define(:identifier => :savings)
          accounts.define(:identifier => :cash)
          accounts.define(:identifier => :credit)
          accounts.define(:identifier => :account_fees)
          accounts.define(:identifier => :service_fees)
        end

        config.define_transfers do |transfers|
          transfers.define(:from => :savings, :to => :cash,         :code => :spend)
          transfers.define(:from => :cash,    :to => :savings,      :code => :save)
          transfers.define(:from => :cash,    :to => :credit,       :code => :bill)
          transfers.define(:from => :savings, :to => :account_fees, :code => :fees)
          transfers.define(:from => :savings, :to => :service_fees, :code => :fees)
        end
      end

      cash         = DoubleEntry.account(:cash)
      savings      = DoubleEntry.account(:savings)
      credit       = DoubleEntry.account(:credit)
      service_fees = DoubleEntry.account(:service_fees)
      account_fees = DoubleEntry.account(:account_fees)
      DoubleEntry.transfer(Money.new(10_00), :from => cash,    :to => savings,      :code => :save, :metadata => { :reason => 'payday' })
      DoubleEntry.transfer(Money.new(10_00), :from => cash,    :to => savings,      :code => :save, :metadata => { :reason => 'payday' })
      DoubleEntry.transfer(Money.new(20_00), :from => cash,    :to => savings,      :code => :save)
      DoubleEntry.transfer(Money.new(20_00), :from => cash,    :to => savings,      :code => :save)
      DoubleEntry.transfer(Money.new(30_00), :from => cash,    :to => credit,       :code => :bill)
      DoubleEntry.transfer(Money.new(40_00), :from => cash,    :to => credit,       :code => :bill)
      DoubleEntry.transfer(Money.new(50_00), :from => savings, :to => cash,         :code => :spend)
      DoubleEntry.transfer(Money.new(60_00), :from => savings, :to => cash,         :code => :spend, :metadata => { :category => 'entertainment' })
      DoubleEntry.transfer(Money.new(70_00), :from => savings, :to => service_fees, :code => :fees)
      DoubleEntry.transfer(Money.new(80_00), :from => savings, :to => account_fees, :code => :fees)
    end

    after do
      # restore "helpful" predefined config
      DoubleEntry.configuration.accounts  = @config_accounts
      DoubleEntry.configuration.transfers = @config_transfers
    end

    describe 'filter solely on transaction identifiers and time' do
      let(:function) { :sum }
      let(:account) { :savings }
      let(:code) { :save }
      let(:range) { DoubleEntry::Reporting::MonthRange.current }

      subject(:aggregate) do
        DoubleEntry::Reporting.aggregate(function, account, code, range)
      end

      specify 'Total attempted to save' do
        expect(aggregate).to eq(Money.new(60_00))
      end
    end

    describe 'filter by named scope that does not take arguments' do
      let(:function) { :sum }
      let(:account) { :savings }
      let(:code) { :save }
      let(:range) { DoubleEntry::Reporting::MonthRange.current }

      subject(:aggregate) do
        DoubleEntry::Reporting.aggregate(function, account, code, range,
          filter: [
            :scope => {
              :name => :ten_dollar_transfers,
            },
          ]
        )
      end

      before do
        DoubleEntry::Line.class_eval do
          scope :ten_dollar_transfers, -> { where(:amount => Money.new(10_00).fractional) }
        end
      end

      specify 'Total amount of $10 transfers attempted to save' do
        expect(aggregate).to eq(Money.new(20_00))
      end
    end

    describe 'filter by named scope that takes arguments' do
      let(:function) { :sum }
      let(:account) { :savings }
      let(:code) { :save }
      let(:range) { DoubleEntry::Reporting::MonthRange.current }

      subject(:aggregate) do
        DoubleEntry::Reporting.aggregate(function, account, code, range,
          filter: [
            :scope => {
              :name      => :specific_transfer_amount,
              :arguments => [Money.new(20_00)],
            },
          ]
        )
      end

      before do
        DoubleEntry::Line.class_eval do
          scope :specific_transfer_amount, ->(amount) { where(:amount => amount.fractional) }
        end
      end

      specify 'Total amount of transfers of $20 attempted to save' do
        expect(aggregate).to eq(Money.new(40_00))
      end
    end

    describe 'filter by metadata' do
      let(:function) { :sum }
      let(:account) { :savings }
      let(:code) { :save }
      let(:range) { DoubleEntry::Reporting::MonthRange.current }

      subject(:aggregate) do
        DoubleEntry::Reporting.aggregate(function, account, code, range,
          filter: [
            :metadata => {
              :reason => 'payday',
            },
          ]
        )
      end

      specify 'Total amount of transfers saved because payday' do
        expect(aggregate).to eq(Money.new(20_00))
      end
    end

    describe 'filter by partner_account' do
      let(:function) { :sum }
      let(:account) { :savings }
      let(:code) { :fees }
      let(:range) { DoubleEntry::Reporting::MonthRange.current }
      let(:partner_account) { :service_fees }
      subject(:aggregate) { DoubleEntry::Reporting.aggregate(function, account, code, range, partner_account: partner_account) }

      specify 'Total amount of service fees paid' do
        expect(aggregate).to eq(Money.new(-70_00))
      end
    end
  end

  describe '.aggregate_array' do
    before do
      # get rid of "helpful" predefined config
      @config_accounts  = DoubleEntry.configuration.accounts
      @config_transfers = DoubleEntry.configuration.transfers
      DoubleEntry.configuration.accounts  = DoubleEntry::Account::Set.new
      DoubleEntry.configuration.transfers = DoubleEntry::Transfer::Set.new

      DoubleEntry.configure do |config|
        config.define_accounts do |accounts|
          accounts.define(:identifier => :savings)
          accounts.define(:identifier => :account_fees)
          accounts.define(:identifier => :service_fees)
        end

        config.define_transfers do |transfers|
          transfers.define(:from => :savings, :to => :account_fees, :code => :fees)
          transfers.define(:from => :savings, :to => :service_fees, :code => :fees)
        end
      end

      savings      = DoubleEntry.account(:savings)
      service_fees = DoubleEntry.account(:service_fees)
      account_fees = DoubleEntry.account(:account_fees)

      Timecop.travel(Time.local(2015, 11)) do
        DoubleEntry.transfer(Money.new(50_00), :from => savings, :to => service_fees, :code => :fees)
        DoubleEntry.transfer(Money.new(60_00), :from => savings, :to => account_fees, :code => :fees)
      end

      Timecop.travel(Time.local(2015, 12)) do
        DoubleEntry.transfer(Money.new(70_00), :from => savings, :to => service_fees, :code => :fees)
        DoubleEntry.transfer(Money.new(80_00), :from => savings, :to => account_fees, :code => :fees)
      end
    end

    after do
      # restore "helpful" predefined config
      DoubleEntry.configuration.accounts  = @config_accounts
      DoubleEntry.configuration.transfers = @config_transfers
    end

    describe 'filter solely on transaction identifiers and time' do
      let(:function) { :sum }
      let(:account) { :savings }
      let(:code) { :fees }
      subject(:aggregate) do
        DoubleEntry::Reporting.aggregate_array(function, account, code, range_type: 'year', start: '2015-01-01')
      end

      before do
        Timecop.travel(Time.local(2016,01,01))
      end

      it { is_expected.to eq [Money.new(-260_00), Money.zero] }
    end

    describe 'filter by partner_account' do
      let(:function) { :sum }
      let(:account) { :savings }
      let(:code) { :fees }
      let(:start) { '2015-01-01' }
      let(:range_type) { 'year' }
      let(:partner_account) { :service_fees }
      subject(:aggregate) do
        DoubleEntry::Reporting.aggregate_array(function, account, code,
          partner_account: partner_account,
          range_type: range_type,
          start: start,
        )
      end

      before do
        Timecop.travel(Time.local(2016,01,01))
      end

      it { is_expected.to eq [Money.new(-120_00), Money.zero] }
    end
  end
end
