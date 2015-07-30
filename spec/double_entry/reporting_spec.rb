# encoding: utf-8
RSpec.describe DoubleEntry::Reporting do
  describe '::configure' do
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

  describe '::scopes_with_minimum_balance_for_account' do
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

  describe '::aggregate' do
    before do
      # get rid of "helpful" predefined config
      @config_accounts = DoubleEntry.configuration.accounts
      @config_transfers = DoubleEntry.configuration.transfers
      DoubleEntry.configuration.accounts = DoubleEntry::Account::Set.new
      DoubleEntry.configuration.transfers = DoubleEntry::Transfer::Set.new

      DoubleEntry.configure do |config|
        config.define_accounts do |accounts|
          accounts.define(:identifier => :savings)
          accounts.define(:identifier => :cash)
          accounts.define(:identifier => :credit)
        end

        config.define_transfers do |transfers|
          transfers.define(:from => :savings, :to => :cash,    :code => :spend)
          transfers.define(:from => :cash,    :to => :savings, :code => :save)
          transfers.define(:from => :cash,    :to => :credit,  :code => :bill)
        end
      end

      cash    = DoubleEntry.account(:cash)
      savings = DoubleEntry.account(:savings)
      credit  = DoubleEntry.account(:credit)
      DoubleEntry.transfer(Money.new(10_00), :from => cash,    :to => savings, :code => :save)
      DoubleEntry.transfer(Money.new(10_00), :from => cash,    :to => savings, :code => :save)
      DoubleEntry.transfer(Money.new(20_00), :from => cash,    :to => savings, :code => :save)
      DoubleEntry.transfer(Money.new(20_00), :from => cash,    :to => savings, :code => :save)
      DoubleEntry.transfer(Money.new(30_00), :from => cash,    :to => credit,  :code => :bill)
      DoubleEntry.transfer(Money.new(40_00), :from => cash,    :to => credit,  :code => :bill)
      DoubleEntry.transfer(Money.new(50_00), :from => savings, :to => cash,    :code => :spend)
      DoubleEntry.transfer(Money.new(60_00), :from => savings, :to => cash,    :code => :spend)

      first_transfer         = DoubleEntry::Line.all[0]
      second_transfer        = DoubleEntry::Line.all[2]
      last_transfer          = DoubleEntry::Line.all[14]
      DoubleEntry::LineMetadata.create!(:line => first_transfer,          :key => :reason,   :value => :payday)
      DoubleEntry::LineMetadata.create!(:line => first_transfer.partner,  :key => :reason,   :value => :payday)
      DoubleEntry::LineMetadata.create!(:line => second_transfer,         :key => :reason,   :value => :payday)
      DoubleEntry::LineMetadata.create!(:line => second_transfer.partner, :key => :reason,   :value => :payday)
      DoubleEntry::LineMetadata.create!(:line => last_transfer,           :key => :category, :value => :entertainment)
      DoubleEntry::LineMetadata.create!(:line => last_transfer.partner,   :key => :category, :value => :entertainment)
    end

    after do
      # restore "helpful" predefined config
      DoubleEntry.configuration.accounts = @config_accounts
      DoubleEntry.configuration.transfers = @config_transfers
    end

    describe 'filter solely on transaction identifiers and time' do
      let(:function) { :sum }
      let(:account) { :savings }
      let(:code) { :save }
      let(:range) { DoubleEntry::Reporting::MonthRange.current }

      subject(:aggregate) do
        DoubleEntry::Reporting.aggregate(function, account, code, :range => range)
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
        DoubleEntry::Reporting.aggregate(
          function, account, code,
          :range  => range,
          :filter => [
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
        DoubleEntry::Reporting.aggregate(
          function, account, code,
          :range  => range,
          :filter => [
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
        DoubleEntry::Reporting.aggregate(
          function, account, code,
          :range  => range,
          :filter => [
            :metadata => {
              :reason => :payday,
            },
          ]
        )
      end

      specify 'Total amount of transfers saved because payday' do
        expect(aggregate).to eq(Money.new(20_00))
      end
    end
  end
end
