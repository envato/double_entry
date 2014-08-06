# encoding: utf-8
require 'spec_helper'
describe DoubleEntry::Configuration do

  its(:accounts) { should be_a DoubleEntry::Account::Set }
  its(:transfers) { should be_a DoubleEntry::Transfer::Set }
  its(:default_currency) { should be_a Money::Currency }

  describe "#define_accounts" do
    it "yields the accounts set" do
      expect { |block|
        subject.define_accounts(&block)
      }.to yield_with_args(be_a DoubleEntry::Account::Set)
    end
  end

  describe "#define_transfers" do
    it "yields the transfers set" do
      expect { |block|
        subject.define_transfers(&block)
      }.to yield_with_args(be_a DoubleEntry::Transfer::Set)
    end
  end

  describe "#set_default_currency" do
    it "Sets the default currency" do
      DoubleEntry.configure do |config|
        config.default_currency = "AUD"
      end
      expect(DoubleEntry.default_currency).to eq(Money::Currency.find(:aud))
    end
  end
end
