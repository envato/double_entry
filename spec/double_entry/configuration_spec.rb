# encoding: utf-8
RSpec.describe DoubleEntry::Configuration do
  its(:accounts) { should be_a DoubleEntry::Account::Set }
  its(:transfers) { should be_a DoubleEntry::Transfer::Set }

  describe "max lengths" do
    context "given a max length has not been set" do
      its(:code_max_length) { should be 47 }
      its(:scope_identifier_max_length) { should be 23 }
      its(:account_identifier_max_length) { should be 31 }
    end

    context "given a code max length of 10 has been set" do
      before { subject.code_max_length = 10 }
      its(:code_max_length) { should be 10 }
    end

    context "given a scope identifier max length of 11 has been set" do
      before { subject.scope_identifier_max_length = 11 }
      its(:scope_identifier_max_length) { should be 11 }
    end

    context "given an account identifier max length of 9 has been set" do
      before { subject.account_identifier_max_length = 9 }
      its(:account_identifier_max_length) { should be 9 }
    end

    after do
      subject.code_max_length = nil
      subject.scope_identifier_max_length = nil
      subject.account_identifier_max_length = nil
    end
  end

  describe "#define_accounts" do
    it "yields the accounts set" do
      expect do |block|
        subject.define_accounts(&block)
      end.to yield_with_args(be_a DoubleEntry::Account::Set)
    end
  end

  describe "#define_transfers" do
    it "yields the transfers set" do
      expect do |block|
        subject.define_transfers(&block)
      end.to yield_with_args(be_a DoubleEntry::Transfer::Set)
    end
  end
end
