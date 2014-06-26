# encoding: utf-8
require 'spec_helper'
describe DoubleEntry::Configuration do

  its(:accounts) { should be_a DoubleEntry::Account::Set }
  its(:transfers) { should be_a DoubleEntry::Transfer::Set }

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
end
