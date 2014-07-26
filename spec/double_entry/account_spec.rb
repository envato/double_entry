# encoding: utf-8
require 'spec_helper'
module DoubleEntry
  describe Account do
    let(:identity_scope) { ->(value) { value } }

    it "instances should be sortable" do
      account = Account.new(:identifier => "savings", :scope_identifier => identity_scope)
      a = Account::Instance.new(:account => account, :scope => "123")
      b = Account::Instance.new(:account => account, :scope => "456")
      expect([b, a].sort).to eq [a, b]
    end

    it "instances should be hashable" do
      account = Account.new(:identifier => "savings", :scope_identifier => identity_scope)
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

    describe "#ar_scope_identifier" do
      subject(:scope) { Account::Set.new.ar_scope_identifier(ar_class) }

      context "given ActiveRecordScopeFactory is stubbed" do
        let(:scope_identifier) { double(:scope_identifier) }
        let(:scope_factory) { double(:scope_factory, :scope_identifier => scope_identifier) }
        let(:ar_class) { double(:ar_class) }
        before { allow(Account::ActiveRecordScopeFactory).to receive(:new).with(ar_class).and_return(scope_factory) }

        it { should eq scope_identifier }
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
