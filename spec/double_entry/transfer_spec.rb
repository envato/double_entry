# encoding: utf-8
require 'spec_helper'
describe DoubleEntry::Transfer::Set do
  describe "#define" do
    before do
      subject.define(
        :code => "code",
        :from => double(:identifier => "from"),
        :to => double(:identifier => "to"),
      )
    end
    its(:first) { should be_a DoubleEntry::Transfer }
    its("first.code") { should eq "code" }
    its("first.from.identifier") { should eq "from" }
    its("first.to.identifier") { should eq "to" }
  end
end
