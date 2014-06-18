# encoding: utf-8
require 'spec_helper'

describe DoubleEntry do

  # these specs blat the DoubleEntry configuration, so take
  # a copy and clean up after ourselves
  before do
    @config_accounts = DoubleEntry.accounts
    @config_transfers = DoubleEntry.transfers
  end

  after do
    DoubleEntry.accounts = @config_accounts
    DoubleEntry.transfers = @config_transfers
  end


  describe 'configuration' do
    it 'checks for duplicates of accounts' do
      expect do
        DoubleEntry.accounts = DoubleEntry::Account::Set.new.tap do |accounts|
          accounts << DoubleEntry::Account.new(:identifier => :gah!)
          accounts << DoubleEntry::Account.new(:identifier => :gah!)
        end
      end.to raise_error(DoubleEntry::DuplicateAccount)
    end

    it 'checks for duplicates of transfers' do
      expect do
        DoubleEntry.transfers = DoubleEntry::Transfer::Set.new.tap do |transfers|
          transfers << DoubleEntry::Transfer.new(:from => :savings, :to => :cash, :code => :xfer)
          transfers << DoubleEntry::Transfer.new(:from => :savings, :to => :cash, :code => :xfer)
        end
      end.to raise_error(DoubleEntry::DuplicateTransfer)
    end
  end

  describe 'accounts' do
    before do
      @scope = double('a scope', :id => 1)

      DoubleEntry.accounts = DoubleEntry::Account::Set.new.tap do |accounts|
        accounts << DoubleEntry::Account.new(:identifier => :unscoped)
        accounts << DoubleEntry::Account.new(:identifier => :scoped, :scope_identifier => lambda { |u| u.id })
      end
    end

    describe 'fetching' do
      it 'can find an unscoped account by identifier' do
        expect(DoubleEntry.account(:unscoped)).to_not be_nil
      end

      it 'can find a scoped account by identifier' do
        expect(DoubleEntry.account(:scoped, :scope => @scope)).to_not be_nil
      end

      it 'raises an exception when it cannot find an account' do
        expect { DoubleEntry.account(:invalid) }.to raise_error(DoubleEntry::UnknownAccount)
      end

      it 'raises exception when you ask for an unscoped account w/ scope' do
        expect { DoubleEntry.account(:unscoped, :scope => @scope) }.to raise_error(DoubleEntry::UnknownAccount)
      end

      it 'raises exception when you ask for a scoped account w/ out scope' do
        expect { DoubleEntry.account(:scoped) }.to raise_error(DoubleEntry::UnknownAccount)
      end
    end

    context "an unscoped account" do
      subject(:unscoped) { DoubleEntry.account(:unscoped) }

      it "has an identifier" do
        expect(unscoped.identifier).to eq :unscoped
      end
    end
    context "a scoped account" do
      subject(:scoped) { DoubleEntry.account(:scoped, :scope => @scope) }

      it "has an identifier" do
        expect(scoped.identifier).to eq :scoped
      end
    end
  end

  describe 'transfers' do
    before do
      DoubleEntry.accounts = DoubleEntry::Account::Set.new.tap do |accounts|
        accounts << DoubleEntry::Account.new(:identifier => :savings)
        accounts << DoubleEntry::Account.new(:identifier => :cash)
        accounts << DoubleEntry::Account.new(:identifier => :trash)
      end

      DoubleEntry.transfers = DoubleEntry::Transfer::Set.new.tap do |transfers|
        transfers << DoubleEntry::Transfer.new(:from => :savings, :to => :cash, :code => :xfer, :meta_requirement => [:ref])
      end

      @savings = DoubleEntry.account(:savings)
      @cash = DoubleEntry.account(:cash)
      @trash = DoubleEntry.account(:trash)
    end

    it 'can transfer from an account to an account, if the transfer is allowed' do
      expect do
        DoubleEntry.transfer(Money.new(100_00), :from => @savings, :to => @cash, :code => :xfer, :meta => {:ref => 'shopping!'})
      end.to_not raise_error
    end

    it 'raises an exception when the transfer is not allowed (wrong direction)' do
      expect do
        DoubleEntry.transfer(Money.new(100_00), :from => @cash, :to => @savings, :code => :xfer)
      end.to raise_error(DoubleEntry::TransferNotAllowed)
    end

    it 'raises an exception when the transfer is not allowed (wrong code)' do
      expect do
        DoubleEntry.transfer(Money.new(100_00), :from => @savings, :to => @cash, :code => :yfer, :meta => {:ref => 'shopping!'})
      end.to raise_error(DoubleEntry::TransferNotAllowed)
    end

    it 'raises an exception when the transfer is not allowed (does not exist, at all)' do
      expect do
        DoubleEntry.transfer(Money.new(100_00), :from => @cash, :to => @trash)
      end.to raise_error(DoubleEntry::TransferNotAllowed)
    end

    it 'raises an exception when required meta data is omitted' do
      expect do
        DoubleEntry.transfer(Money.new(100_00), :from => @savings, :to => @cash, :code => :xfer, :meta => {})
      end.to raise_error(DoubleEntry::RequiredMetaMissing)
    end
  end

  describe 'lines' do
    before do
      DoubleEntry.accounts = DoubleEntry::Account::Set.new.tap do |accounts|
        accounts << DoubleEntry::Account.new(:identifier => :a)
        accounts << DoubleEntry::Account.new(:identifier => :b)
      end

      DoubleEntry.transfers = DoubleEntry::Transfer::Set.new.tap do |transfers|
        description = lambda do |line|
          "Money goes #{line.credit? ? 'out' : 'in'}: #{line.amount.format}"
        end
        transfers << DoubleEntry::Transfer.new(:code => :xfer, :from => :a, :to => :b, :description => description)
      end

      @a, @b = DoubleEntry.account(:a), DoubleEntry.account(:b)
      DoubleEntry.transfer(Money.new(10_00), :from => @a, :to => @b, :code => :xfer)
      @credit = lines_for_account(@a).first
      @debit  = lines_for_account(@b).first
    end

    it 'has an amount' do
      expect(@credit.amount).to eq -Money.new(10_00)
      expect(@debit.amount).to eq Money.new(10_00)
    end

    it 'has a code' do
      expect(@credit.code).to eq :xfer
      expect(@debit.code).to eq :xfer
    end

    it 'auto-sets scope when assigning account (and partner_accout, is this implementation?)' do
      expect(@credit[:account]).to eq 'a'
      expect(@credit[:scope]).to be_nil
      expect(@credit[:partner_account]).to eq 'b'
      expect(@credit[:partner_scope]).to be_nil
    end

    it 'has a partner_account (or is this implementation?)' do
      expect(@credit.partner_account).to eq @debit.account
    end

    it 'knows if it is a credit or debit' do
      expect(@credit).to be_credit
      expect(@debit).to be_debit
      expect(@credit).to_not be_debit
      expect(@debit).to_not be_credit
    end

    it 'can describe itself' do
      expect(@credit.description).to eq 'Money goes out: $-10.00'
      expect(@debit.description).to eq 'Money goes in: $10.00'
    end

    it 'can reference its partner' do
      expect(@credit.partner).to eq @debit
      expect(@debit.partner).to eq @credit
    end

    it 'can ask for its pair (credit always coming first)' do
      expect(@credit.pair).to eq [@credit, @debit]
      expect(@debit.pair).to eq [@credit, @debit]
    end

    it 'can ask for the account (and get an instance)' do
      expect(@credit.account).to eq @a
      expect(@debit.account).to eq @b
    end
  end

  describe 'balances' do
    before do
      DoubleEntry.accounts = DoubleEntry::Account::Set.new.tap do |accounts|
        accounts << DoubleEntry::Account.new(:identifier => :work)
        accounts << DoubleEntry::Account.new(:identifier => :cash)
        accounts << DoubleEntry::Account.new(:identifier => :savings)
        accounts << DoubleEntry::Account.new(:identifier => :store)
      end

      DoubleEntry.transfers = DoubleEntry::Transfer::Set.new.tap do |transfers|
        transfers << DoubleEntry::Transfer.new(:code => :salary, :from => :work, :to => :cash)
        transfers << DoubleEntry::Transfer.new(:code => :xfer, :from => :cash, :to => :savings)
        transfers << DoubleEntry::Transfer.new(:code => :xfer, :from => :savings, :to => :cash)
        transfers << DoubleEntry::Transfer.new(:code => :purchase, :from => :cash, :to => :store)
        transfers << DoubleEntry::Transfer.new(:code => :layby, :from => :cash, :to => :store)
        transfers << DoubleEntry::Transfer.new(:code => :deposit, :from => :cash, :to => :store)
      end

      @work = DoubleEntry.account(:work)
      @savings = DoubleEntry.account(:savings)
      @cash = DoubleEntry.account(:cash)
      @store = DoubleEntry.account(:store)

      Timecop.freeze 3.weeks.ago+1.day do
        # got paid from work
        DoubleEntry.transfer(Money.new(1_000_00), :from => @work, :code => :salary, :to => @cash)
        # transfer half salary into savings
        DoubleEntry.transfer(Money.new(500_00), :from => @cash, :code => :xfer, :to => @savings)
      end

      Timecop.freeze 2.weeks.ago+1.day do
        # got myself a darth vader helmet
        DoubleEntry.transfer(Money.new(200_00), :from => @cash, :code => :purchase, :to => @store)
        # paid off some of my darth vader suit layby (to go with the helmet)
        DoubleEntry.transfer(Money.new(100_00), :from => @cash, :code => :layby, :to => @store)
        # put a deposit on the darth vader voice changer module (for the helmet)
        DoubleEntry.transfer(Money.new(100_00), :from => @cash, :code => :deposit, :to => @store)
      end

      Timecop.freeze 1.week.ago+1.day do
        # transfer 200 out of savings
        DoubleEntry.transfer(Money.new(200_00), :from => @savings, :code => :xfer, :to => @cash)
        # pay the remaining balance on the darth vader voice changer module
        DoubleEntry.transfer(Money.new(200_00), :from => @cash, :code => :purchase, :to => @store)
      end

      Timecop.freeze 1.week.from_now do
        # go to the star wars convention AND ROCK OUT IN YOUR ACE DARTH VADER COSTUME!!!
      end
    end

    it 'has the initial balances that we expect' do
      expect(@work.balance).to eq -Money.new(1_000_00)
      expect(@cash.balance).to eq Money.new(100_00)
      expect(@savings.balance).to eq Money.new(300_00)
      expect(@store.balance).to eq Money.new(600_00)
    end

    it 'should have correct account balance records' do
      [@work, @cash, @savings, @store].each do |account|
        expect(DoubleEntry::AccountBalance.find_by_account(account).balance).to eq account.balance
      end
    end

    it 'affects origin/destination balance after transfer' do
      @savings_balance = @savings.balance
      @cash_balance = @cash.balance
      @amount = Money.new(10_00)

      DoubleEntry.transfer(@amount, :from => @savings, :code => :xfer, :to => @cash)

      expect(@savings.balance).to eq @savings_balance - @amount
      expect(@cash.balance).to eq @cash_balance + @amount
    end

    it 'can be queried at a given point in time' do
      expect(@cash.balance(:at => 1.week.ago)).to eq Money.new(100_00)
    end

    it 'can be queries between two points in time' do
      expect(@cash.balance(:from => 3.weeks.ago, :to => 2.weeks.ago)).to eq Money.new(500_00)
    end

    it 'can report on balances, scoped by code' do
      expect(@cash.balance(:code => :salary)).to eq Money.new(1_000_00)
    end

    it 'can report on balances, scoped by many codes' do
      expect(@store.balance(:codes => [:layby, :deposit])).to eq Money.new(200_00)
    end

    it 'has running balances for each line' do
      @lines = lines_for_account(@cash)
      expect(@lines[0].balance).to eq Money.new(1_000_00) # salary
      expect(@lines[1].balance).to eq Money.new(500_00) # savings
      expect(@lines[2].balance).to eq Money.new(300_00) # purchase
      expect(@lines[3].balance).to eq Money.new(200_00) # layby
      expect(@lines[4].balance).to eq Money.new(100_00) # deposit
      expect(@lines[5].balance).to eq Money.new(300_00) # savings
      expect(@lines[6].balance).to eq Money.new(100_00) # purchase
    end
  end

  describe 'scoping of accounts' do
    before do
      DoubleEntry.accounts = DoubleEntry::Account::Set.new.tap do |accounts|
        accounts << DoubleEntry::Account.new(:identifier => :bank)
        accounts << DoubleEntry::Account.new(:identifier => :cash, :scope_identifier => lambda { |user| user.id })
        accounts << DoubleEntry::Account.new(:identifier => :savings, :scope_identifier => lambda { |user| user.id })
      end

      DoubleEntry.transfers = DoubleEntry::Transfer::Set.new.tap do |transfers|
        transfers << DoubleEntry::Transfer.new(:from => :bank, :to => :cash, :code => :xfer)
        transfers << DoubleEntry::Transfer.new(:from => :cash, :to => :cash, :code => :xfer)
        transfers << DoubleEntry::Transfer.new(:from => :cash, :to => :savings, :code => :xfer)
      end

      @john = User.make!
      @ryan = User.make!

      @bank = DoubleEntry.account(:bank)
      @johns_cash = DoubleEntry.account(:cash, :scope => @john)
      @johns_savings = DoubleEntry.account(:savings, :scope => @john)
      @ryans_cash = DoubleEntry.account(:cash, :scope => @ryan)
      @ryans_savings = DoubleEntry.account(:savings, :scope => @ryan)
    end

    it 'treats each separately scoped account having their own separate balances' do
      DoubleEntry.transfer(Money.new(20_00), :from => @bank, :to => @johns_cash, :code => :xfer)
      DoubleEntry.transfer(Money.new(10_00), :from => @bank, :to => @ryans_cash, :code => :xfer)
      expect(@johns_cash.balance).to eq Money.new(20_00)
      expect(@ryans_cash.balance).to eq Money.new(10_00)
    end

    it 'allows transfer between two separately scoped accounts' do
      DoubleEntry.transfer(Money.new(10_00), :from => @ryans_cash, :to => @johns_cash, :code => :xfer)
      expect(@ryans_cash.balance).to eq -Money.new(10_00)
      expect(@johns_cash.balance).to eq Money.new(10_00)
    end

    it 'reports balance correctly if called from either account or finances object' do
      DoubleEntry.transfer(Money.new(10_00), :from => @ryans_cash, :to => @johns_cash, :code => :xfer)
      expect(@ryans_cash.balance).to eq -Money.new(10_00)
      expect(DoubleEntry.balance(:cash, :scope => @ryan)).to eq -Money.new(10_00)
    end

    it 'raises exception if you try to transfer between the same account, despite it being scoped' do
      expect do
        DoubleEntry.transfer(Money.new(10_00), :from => @ryans_cash, :to => @ryans_cash, :code => :xfer)
      end.to raise_error(DoubleEntry::TransferNotAllowed)
    end

    it 'allows transfer from one persons account to the same persons other kind of account' do
      DoubleEntry.transfer(Money.new(100_00), :from => @ryans_cash, :to => @ryans_savings, :code => :xfer)
      expect(@ryans_cash.balance).to eq -Money.new(100_00)
      expect(@ryans_savings.balance).to eq Money.new(100_00)
    end

    it 'allows you to report on scoped accounts globally' do
      expect(DoubleEntry.balance(:cash)).to eq @ryans_cash.balance+@johns_cash.balance
      expect(DoubleEntry.balance(:savings)).to eq @ryans_savings.balance+@johns_savings.balance
    end
  end

  describe "::scopes_with_minimum_balance_for_account" do
    subject(:scopes) { DoubleEntry.scopes_with_minimum_balance_for_account(minimum_balance, :checking) }

    context "a 'checking' account with balance $100" do
      let!(:user) { User.make!(:checking_balance => Money.new(100_00)) }

      context "when searching for balance $99" do
        let(:minimum_balance) { Money.new(99_00) }
        it { should include user.id }
      end

      context "when searching for balance $100" do
        let(:minimum_balance) { Money.new(100_00) }
        it { should include user.id }
      end

      context "when searching for balance $101" do
        let(:minimum_balance) { Money.new(101_00) }
        it { should_not include user.id }
      end
    end
  end

end
