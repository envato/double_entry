# encoding: utf-8
require 'spec_helper'
describe DoubleEntry::Account do
  let(:empty_scope) { lambda {|value| value } }

  it "instances should be sortable" do
    account = DoubleEntry::Account.new(:identifier => "savings", :scope_identifier => empty_scope)
    a = DoubleEntry::Account::Instance.new(:account => account, :scope => "123")
    b = DoubleEntry::Account::Instance.new(:account => account, :scope => "456")
    expect([b, a].sort).to eq [a, b]
  end

  it "instances should be hashable" do
    account = DoubleEntry::Account.new(:identifier => "savings", :scope_identifier => empty_scope)
    a1 = DoubleEntry::Account::Instance.new(:account => account, :scope => "123")
    a2 = DoubleEntry::Account::Instance.new(:account => account, :scope => "123")
    b  = DoubleEntry::Account::Instance.new(:account => account, :scope => "456")

    expect(a1.hash).to eq a2.hash
    expect(a1.hash).to_not eq b.hash
  end

end
