# encoding: utf-8
require 'spec_helper'
module DoubleEntry
  describe Account do
    let(:empty_scope) { lambda {|value| value } }

    it "instances should be sortable" do
      account = Account.new(:identifier => "savings", :scope_identifier => empty_scope)
      a = Account::Instance.new(:account => account, :scope => "123")
      b = Account::Instance.new(:account => account, :scope => "456")
      expect([b, a].sort).to eq [a, b]
    end

    it "instances should be hashable" do
      account = Account.new(:identifier => "savings", :scope_identifier => empty_scope)
      a1 = Account::Instance.new(:account => account, :scope => "123")
      a2 = Account::Instance.new(:account => account, :scope => "123")
      b  = Account::Instance.new(:account => account, :scope => "456")

      expect(a1.hash).to eq a2.hash
      expect(a1.hash).to_not eq b.hash
    end
  end

  describe Account::Set do
    describe "#define" do
      context "given a 'savings' account is defined" do
        before { subject.define(:identifier => "savings") }
        its(:first) { should be_a Account }
        its("first.identifier") { should eq "savings" }
      end
    end
  end

  describe Account::ActiveRecordScopeFactory do
    context "given the class User" do
      subject(:factory) { Account::ActiveRecordScopeFactory.new(User) }

      describe "#scope_identifier" do
        subject(:scope_identifier) { factory.scope_identifier }

        describe "#call" do
          subject(:scope) { scope_identifier.call(value) }

          context "given a User instance with ID 32" do
            let(:value) { User.make(:id => 32) }

            it { should eq 32 }
          end

          context "given the String 'I am a bearded lady'" do
            let(:value) { "I am a bearded lady" }

            it { should eq "I am a bearded lady" }
          end

          context "given the Integer 42" do
            let(:value) { 42 }

            it { should eq 42 }
          end
        end
      end
    end
  end
end
