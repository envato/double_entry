# encoding: utf-8
require "spec_helper"
describe DoubleEntry::Line do
  it "has a table name prefixed with double_entry_" do
    expect(DoubleEntry::Line.table_name).to eq "double_entry_lines"
  end

  describe "persistance" do
    let(:persisted_line) {
      DoubleEntry::Line.new(
        :amount => Money.new(10_00),
        :balance => Money.empty,
        :account => account,
        :partner_account => partner_account,
        :code => code,
      )
    }
    let(:account) { DoubleEntry.account(:test, :scope => "17") }
    let(:partner_account) { DoubleEntry.account(:test, :scope => "72") }
    let(:code) { :test_code }
    subject { DoubleEntry::Line.last }

    describe "attributes" do
      before { persisted_line.save! }

      context "given code = :the_code" do
        let(:code) { :the_code }
        its(:code) { should eq :the_code }
      end

      context "given code = nil" do
        let(:code) { nil }
        its(:code) { should eq nil }
      end

      context "given account = :test, 54 " do
        let(:account) { DoubleEntry.account(:test, :scope => "54") }
        its("account.account.identifier") { should eq :test }
        its("account.scope") { should eq "54" }
      end

      context "given partner_account = :test, 91 " do
        let(:partner_account) { DoubleEntry.account(:test, :scope => "91") }
        its("partner_account.account.identifier") { should eq :test }
        its("partner_account.scope") { should eq "91" }
      end

      context "currency" do
        let(:account) { DoubleEntry.account(:btc_test, :scope => "17") }
        let(:partner_account) { DoubleEntry.account(:btc_test, :scope => "72") }
        its(:currency) { should eq "BTC" }
      end
    end
  end
end
