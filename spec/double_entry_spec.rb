# encoding: utf-8
require 'spec_helper'
describe DoubleEntry do

  # these specs blat the DoubleEntry configuration, so take
  # a copy and clean up after ourselves
  before do
    @config_accounts = DoubleEntry.configuration.accounts
    @config_transfers = DoubleEntry.configuration.transfers
    DoubleEntry.configuration.accounts = DoubleEntry::Account::Set.new
    DoubleEntry.configuration.transfers = DoubleEntry::Transfer::Set.new
  end

  after do
    DoubleEntry.configuration.accounts = @config_accounts
    DoubleEntry.configuration.transfers = @config_transfers
  end

  describe 'configuration' do
    it 'checks for duplicates of accounts' do
      expect {
        DoubleEntry.configure do |config|
          config.define_accounts do |accounts|
            accounts.define(:identifier => :gah!)
            accounts.define(:identifier => :gah!)
          end
        end
      }.to raise_error DoubleEntry::DuplicateAccount
    end

    it 'checks for duplicates of transfers' do
      expect {
        DoubleEntry.configure do |config|
          config.define_transfers do |transfers|
            transfers.define(:from => :savings, :to => :cash, :code => :xfer)
            transfers.define(:from => :savings, :to => :cash, :code => :xfer)
          end
        end
      }.to raise_error DoubleEntry::DuplicateTransfer
    end
  end

  describe 'accounts' do
    before do
      DoubleEntry.configure do |config|
        config.define_accounts do |accounts|
          accounts.define(:identifier => :unscoped)
          accounts.define(:identifier => :scoped, :scope_identifier => ->(u) { u.id })
        end
      end
    end

    let(:scope) { double('a scope', :id => 1) }

    describe 'fetching' do
      it 'can find an unscoped account by identifier' do
        expect(DoubleEntry.account(:unscoped)).to_not be_nil
      end

      it 'can find a scoped account by identifier' do
        expect(DoubleEntry.account(:scoped, :scope => scope)).to_not be_nil
      end

      it 'raises an exception when it cannot find an account' do
        expect { DoubleEntry.account(:invalid) }.to raise_error(DoubleEntry::UnknownAccount)
      end

      it 'raises exception when you ask for an unscoped account w/ scope' do
        expect { DoubleEntry.account(:unscoped, :scope => scope) }.to raise_error(DoubleEntry::UnknownAccount)
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
      subject(:scoped) { DoubleEntry.account(:scoped, :scope => scope) }

      it "has an identifier" do
        expect(scoped.identifier).to eq :scoped
      end
    end
  end

  describe 'transfers' do
    before do
      DoubleEntry.configure do |config|
        config.define_accounts do |accounts|
          accounts.define(:identifier => :savings)
          accounts.define(:identifier => :cash)
          accounts.define(:identifier => :trash)
        end

        config.define_transfers do |transfers|
          transfers.define(:from => :savings, :to => :cash, :code => :xfer, :meta_requirement => [:ref])
        end
      end
    end

    let(:savings) { DoubleEntry.account(:savings) }
    let(:cash)    { DoubleEntry.account(:cash) }
    let(:trash)   { DoubleEntry.account(:trash) }

    it 'can transfer from an account to an account, if the transfer is allowed' do
      DoubleEntry.transfer(
        Money.new(100_00),
        :from => savings,
        :to   => cash,
        :code => :xfer,
        :meta => { :ref => 'shopping!' },
      )
    end

    it 'raises an exception when the transfer is not allowed (wrong direction)' do
      expect {
        DoubleEntry.transfer(
          Money.new(100_00),
          :from => cash,
          :to   => savings,
          :code => :xfer,
        )
      }.to raise_error DoubleEntry::TransferNotAllowed
    end

    it 'raises an exception when the transfer is not allowed (wrong code)' do
      expect {
        DoubleEntry.transfer(
          Money.new(100_00),
          :from => savings,
          :to   => cash,
          :code => :yfer,
          :meta => { :ref => 'shopping!' },
        )
      }.to raise_error DoubleEntry::TransferNotAllowed
    end

    it 'raises an exception when the transfer is not allowed (does not exist, at all)' do
      expect {
        DoubleEntry.transfer(
          Money.new(100_00),
          :from => cash,
          :to   => trash,
        )
      }.to raise_error DoubleEntry::TransferNotAllowed
    end

    it 'raises an exception when required meta data is omitted' do
      expect {
        DoubleEntry.transfer(
          Money.new(100_00),
          :from => savings,
          :to   => cash,
          :code => :xfer,
          :meta => {},
        )
      }.to raise_error DoubleEntry::RequiredMetaMissing
    end
  end

  describe 'lines' do
    before do
      DoubleEntry.configure do |config|
        config.define_accounts do |accounts|
          accounts.define(:identifier => :a)
          accounts.define(:identifier => :b)
        end

        description = ->(line) { "Money goes #{line.credit? ? 'out' : 'in'}: #{line.amount.format}" }
        config.define_transfers do |transfers|
          transfers.define(:code => :xfer, :from => :a, :to => :b, :description => description)
        end
      end

      DoubleEntry.transfer(Money.new(10_00), :from => account_a, :to => account_b, :code => :xfer)
    end

    let(:account_a) { DoubleEntry.account(:a) }
    let(:account_b) { DoubleEntry.account(:b) }
    let(:credit_line) { lines_for_account(account_a).first }
    let(:debit_line) { lines_for_account(account_b).first }

    it 'has an amount' do
      expect(credit_line.amount).to eq -Money.new(10_00)
      expect(debit_line.amount).to eq Money.new(10_00)
    end

    it 'has a code' do
      expect(credit_line.code).to eq :xfer
      expect(debit_line.code).to eq :xfer
    end

    it 'auto-sets scope when assigning account (and partner_accout, is this implementation?)' do
      expect(credit_line[:account]).to eq 'a'
      expect(credit_line[:scope]).to be_nil
      expect(credit_line[:partner_account]).to eq 'b'
      expect(credit_line[:partner_scope]).to be_nil
    end

    it 'has a partner_account (or is this implementation?)' do
      expect(credit_line.partner_account).to eq debit_line.account
    end

    it 'knows if it is a credit or debit' do
      expect(credit_line).to be_credit
      expect(debit_line).to be_debit
      expect(credit_line).to_not be_debit
      expect(debit_line).to_not be_credit
    end

    it 'can describe itself' do
      expect(credit_line.description).to eq 'Money goes out: $-10.00'
      expect(debit_line.description).to eq 'Money goes in: $10.00'
    end

    it 'can reference its partner' do
      expect(credit_line.partner).to eq debit_line
      expect(debit_line.partner).to eq credit_line
    end

    it 'can ask for its pair (credit always coming first)' do
      expect(credit_line.pair).to eq [credit_line, debit_line]
      expect(debit_line.pair).to eq [credit_line, debit_line]
    end

    it 'can ask for the account (and get an instance)' do
      expect(credit_line.account).to eq account_a
      expect(debit_line.account).to eq account_b
    end
  end

  describe 'balances' do

    let(:work)    { DoubleEntry.account(:work) }
    let(:savings) { DoubleEntry.account(:savings) }
    let(:cash)    { DoubleEntry.account(:cash) }
    let(:store)   { DoubleEntry.account(:store) }

    before do
      DoubleEntry.configure do |config|
        config.define_accounts do |accounts|
          accounts.define(:identifier => :work)
          accounts.define(:identifier => :cash)
          accounts.define(:identifier => :savings)
          accounts.define(:identifier => :store)
        end

        config.define_transfers do |transfers|
          transfers.define(:code => :salary,   :from => :work,    :to => :cash)
          transfers.define(:code => :xfer,     :from => :cash,    :to => :savings)
          transfers.define(:code => :xfer,     :from => :savings, :to => :cash)
          transfers.define(:code => :purchase, :from => :cash,    :to => :store)
          transfers.define(:code => :layby,    :from => :cash,    :to => :store)
          transfers.define(:code => :deposit,  :from => :cash,    :to => :store)
        end
      end

      Timecop.freeze 3.weeks.ago+1.day do
        # got paid from work
        DoubleEntry.transfer(Money.new(1_000_00), :from => work, :code => :salary, :to => cash)
        # transfer half salary into savings
        DoubleEntry.transfer(Money.new(500_00), :from => cash, :code => :xfer, :to => savings)
      end

      Timecop.freeze 2.weeks.ago+1.day do
        # got myself a darth vader helmet
        DoubleEntry.transfer(Money.new(200_00), :from => cash, :code => :purchase, :to => store)
        # paid off some of my darth vader suit layby (to go with the helmet)
        DoubleEntry.transfer(Money.new(100_00), :from => cash, :code => :layby, :to => store)
        # put a deposit on the darth vader voice changer module (for the helmet)
        DoubleEntry.transfer(Money.new(100_00), :from => cash, :code => :deposit, :to => store)
      end

      Timecop.freeze 1.week.ago+1.day do
        # transfer 200 out of savings
        DoubleEntry.transfer(Money.new(200_00), :from => savings, :code => :xfer, :to => cash)
        # pay the remaining balance on the darth vader voice changer module
        DoubleEntry.transfer(Money.new(200_00), :from => cash, :code => :purchase, :to => store)
      end

      Timecop.freeze 1.week.from_now do
        # go to the star wars convention AND ROCK OUT IN YOUR ACE DARTH VADER COSTUME!!!
      end
    end

    it 'has the initial balances that we expect' do
      expect(work.balance).to eq -Money.new(1_000_00)
      expect(cash.balance).to eq Money.new(100_00)
      expect(savings.balance).to eq Money.new(300_00)
      expect(store.balance).to eq Money.new(600_00)
    end

    it 'should have correct account balance records' do
      [work, cash, savings, store].each do |account|
        expect(DoubleEntry::AccountBalance.find_by_account(account).balance).to eq account.balance
      end
    end

    it 'affects origin/destination balance after transfer' do
      savings_balance = savings.balance
      cash_balance = cash.balance
      amount = Money.new(10_00)

      DoubleEntry.transfer(amount, :from => savings, :code => :xfer, :to => cash)

      expect(savings.balance).to eq savings_balance - amount
      expect(cash.balance).to eq cash_balance + amount
    end

    it 'can be queried at a given point in time' do
      expect(cash.balance(:at => 1.week.ago)).to eq Money.new(100_00)
    end

    it 'can be queries between two points in time' do
      expect(cash.balance(:from => 3.weeks.ago, :to => 2.weeks.ago)).to eq Money.new(500_00)
    end

    it 'can report on balances, scoped by code' do
      expect(cash.balance(:code => :salary)).to eq Money.new(1_000_00)
    end

    it 'can report on balances, scoped by many codes' do
      expect(store.balance(:codes => [:layby, :deposit])).to eq Money.new(200_00)
    end

    it 'has running balances for each line' do
      lines = lines_for_account(cash)
      expect(lines[0].balance).to eq Money.new(1_000_00) # salary
      expect(lines[1].balance).to eq Money.new(500_00) # savings
      expect(lines[2].balance).to eq Money.new(300_00) # purchase
      expect(lines[3].balance).to eq Money.new(200_00) # layby
      expect(lines[4].balance).to eq Money.new(100_00) # deposit
      expect(lines[5].balance).to eq Money.new(300_00) # savings
      expect(lines[6].balance).to eq Money.new(100_00) # purchase
    end
  end

  describe 'scoping of accounts' do
    before do
      DoubleEntry.configure do |config|
        config.define_accounts do |accounts|
          accounts.define(:identifier => :bank)
          accounts.define(:identifier => :cash,    :scope_identifier => ->(user) { user.id })
          accounts.define(:identifier => :savings, :scope_identifier => ->(user) { user.id })
        end

        config.define_transfers do |transfers|
          transfers.define(:from => :bank, :to => :cash,    :code => :xfer)
          transfers.define(:from => :cash, :to => :cash,    :code => :xfer)
          transfers.define(:from => :cash, :to => :savings, :code => :xfer)
        end
      end
    end

    let(:bank) { DoubleEntry.account(:bank) }

    let(:john) { User.make! }
    let(:johns_cash) { DoubleEntry.account(:cash, :scope => john) }
    let(:johns_savings) { DoubleEntry.account(:savings, :scope => john) }

    let(:ryan) { User.make! }
    let(:ryans_cash) { DoubleEntry.account(:cash, :scope => ryan) }
    let(:ryans_savings) { DoubleEntry.account(:savings, :scope => ryan) }

    it 'treats each separately scoped account having their own separate balances' do
      DoubleEntry.transfer(Money.new(20_00), :from => bank, :to => johns_cash, :code => :xfer)
      DoubleEntry.transfer(Money.new(10_00), :from => bank, :to => ryans_cash, :code => :xfer)
      expect(johns_cash.balance).to eq Money.new(20_00)
      expect(ryans_cash.balance).to eq Money.new(10_00)
    end

    it 'allows transfer between two separately scoped accounts' do
      DoubleEntry.transfer(Money.new(10_00), :from => ryans_cash, :to => johns_cash, :code => :xfer)
      expect(ryans_cash.balance).to eq -Money.new(10_00)
      expect(johns_cash.balance).to eq Money.new(10_00)
    end

    it 'reports balance correctly if called from either account or finances object' do
      DoubleEntry.transfer(Money.new(10_00), :from => ryans_cash, :to => johns_cash, :code => :xfer)
      expect(ryans_cash.balance).to eq -Money.new(10_00)
      expect(DoubleEntry.balance(:cash, :scope => ryan)).to eq -Money.new(10_00)
    end

    it 'raises exception if you try to transfer between the same account, despite it being scoped' do
      expect do
        DoubleEntry.transfer(Money.new(10_00), :from => ryans_cash, :to => ryans_cash, :code => :xfer)
      end.to raise_error(DoubleEntry::TransferNotAllowed)
    end

    it 'allows transfer from one persons account to the same persons other kind of account' do
      DoubleEntry.transfer(Money.new(100_00), :from => ryans_cash, :to => ryans_savings, :code => :xfer)
      expect(ryans_cash.balance).to eq -Money.new(100_00)
      expect(ryans_savings.balance).to eq Money.new(100_00)
    end

    it 'allows you to report on scoped accounts globally' do
      expect(DoubleEntry.balance(:cash)).to eq ryans_cash.balance + johns_cash.balance
      expect(DoubleEntry.balance(:savings)).to eq ryans_savings.balance + johns_savings.balance
    end
  end

end
