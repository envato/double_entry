# encoding: utf-8
require 'spec_helper'

describe DoubleEntry::Locking do

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

  before do
    scope = ->(x) { x }

    DoubleEntry.configure do |config|
      config.define_accounts do |accounts|
        accounts.define(:identifier => :account_a, :scope_identifier => scope)
        accounts.define(:identifier => :account_b, :scope_identifier => scope)
        accounts.define(:identifier => :account_c, :scope_identifier => scope)
        accounts.define(:identifier => :account_d, :scope_identifier => scope)
      end

      config.define_transfers do |transfers|
        transfers.define(:from => :account_a, :to => :account_b, :code => :test)
        transfers.define(:from => :account_c, :to => :account_d, :code => :test)
      end
    end

    @account_a = DoubleEntry.account(:account_a, :scope => "1")
    @account_b = DoubleEntry.account(:account_b, :scope => "2")
    @account_c = DoubleEntry.account(:account_c, :scope => "3")
    @account_d = DoubleEntry.account(:account_d, :scope => "4")
  end

  it "creates missing account balance records" do
    expect do
      DoubleEntry::Locking.lock_accounts(@account_a) { }
    end.to change(DoubleEntry::AccountBalance, :count).by(1)

    account_balance = DoubleEntry::AccountBalance.find_by_account(@account_a)
    expect(account_balance).to_not be_nil
    expect(account_balance.balance).to eq Money.new(0)
  end

  it "takes the balance for new account balance records from the lines table" do
    DoubleEntry::Line.create!(:account => @account_a, :amount => Money.new(3_00), :balance => Money.new( 3_00), :code => :test)
    DoubleEntry::Line.create!(:account => @account_a, :amount => Money.new(7_00), :balance => Money.new(10_00), :code => :test)

    expect do
      DoubleEntry::Locking.lock_accounts(@account_a) { }
    end.to change(DoubleEntry::AccountBalance, :count).by(1)

    account_balance = DoubleEntry::AccountBalance.find_by_account(@account_a)
    expect(account_balance).to_not be_nil
    expect(account_balance.balance).to eq Money.new(10_00)
  end

  it "prohibits locking inside a regular transaction" do
    expect {
      DoubleEntry::AccountBalance.transaction do
        DoubleEntry::Locking.lock_accounts(@account_a, @account_b) do
        end
      end
    }.to raise_error(DoubleEntry::Locking::LockMustBeOutermostTransaction)
  end

  it "prohibits a transfer inside a regular transaction" do
    expect {
      DoubleEntry::AccountBalance.transaction do
        DoubleEntry.transfer(Money.new(10_00), :from => @account_a, :to => @account_b, :code => :test)
      end
    }.to raise_error(DoubleEntry::Locking::LockMustBeOutermostTransaction)
  end

  it "allows a transfer inside a lock if we've locked the transaction accounts" do
    expect {
      DoubleEntry::Locking.lock_accounts(@account_a, @account_b) do
        DoubleEntry.transfer(Money.new(10_00), :from => @account_a, :to => @account_b, :code => :test)
      end
    }.to_not raise_error
  end

  it "does not allow a transfer inside a lock if the right locks aren't held" do
    expect {
      DoubleEntry::Locking.lock_accounts(@account_a, @account_c) do
        DoubleEntry.transfer(Money.new(10_00), :from => @account_a, :to => @account_b, :code => :test)
      end
    }.to raise_error(DoubleEntry::Locking::LockNotHeld, "No lock held for account: account_b, scope 2")
  end

  it "allows nested locks if the outer lock locks all the accounts" do
    expect do
      DoubleEntry::Locking.lock_accounts(@account_a, @account_b) do
        DoubleEntry::Locking.lock_accounts(@account_a, @account_b) { }
      end
    end.to_not raise_error
  end

  it "prohibits nested locks if the out lock doesn't lock all the accounts" do
    expect do
      DoubleEntry::Locking.lock_accounts(@account_a) do
        DoubleEntry::Locking.lock_accounts(@account_a, @account_b) { }
      end
    end.to raise_error(DoubleEntry::Locking::LockNotHeld, "No lock held for account: account_b, scope 2")
  end

  it "rolls back a locking transaction" do
    DoubleEntry::Locking.lock_accounts(@account_a, @account_b) do
      DoubleEntry.transfer(Money.new(10_00), :from => @account_a, :to => @account_b, :code => :test)
      raise ActiveRecord::Rollback
    end
    expect(DoubleEntry.balance(@account_a)).to eq Money.new(0)
    expect(DoubleEntry.balance(@account_b)).to eq Money.new(0)
  end

  it "rolls back a locking transaction if there's an exception" do
    expect do
      DoubleEntry::Locking.lock_accounts(@account_a, @account_b) do
        DoubleEntry.transfer(Money.new(10_00), :from => @account_a, :to => @account_b, :code => :test)
        raise "Yeah, right"
      end
    end.to raise_error("Yeah, right")
    expect(DoubleEntry.balance(@account_a)).to eq Money.new(0)
    expect(DoubleEntry.balance(@account_b)).to eq Money.new(0)
  end

  it "allows multiple threads to lock at the same time" do
    expect do
      threads = Array.new

      threads << Thread.new do
        sleep 0.05
        DoubleEntry::Locking.lock_accounts(@account_a, @account_b) do
          DoubleEntry.transfer(Money.new(10_00), :from => @account_a, :to => @account_b, :code => :test)
        end
      end

      threads << Thread.new do
        DoubleEntry::Locking.lock_accounts(@account_c, @account_d) do
          sleep 0.1
          DoubleEntry.transfer(Money.new(10_00), :from => @account_c, :to => @account_d, :code => :test)
        end
      end

      threads.each(&:join)

    end.to_not raise_error
  end

  it "allows multiple threads to lock accounts without balances at the same time" do
    threads = Array.new
    expect do
      threads << Thread.new { DoubleEntry::Locking.lock_accounts(@account_a, @account_b) { sleep 0.1 } }
      threads << Thread.new { DoubleEntry::Locking.lock_accounts(@account_c, @account_d) { sleep 0.1 } }

      threads.each(&:join)
    end.to_not raise_error
  end
end
