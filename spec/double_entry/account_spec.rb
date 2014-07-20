# encoding: utf-8
require 'spec_helper'
module DoubleEntry
  describe Account do
    let(:identity_scope) { ->(value) { value } }

    describe "::new" do
      context "given an identifier 31 characters in length" do
        let(:identifier) { "xxxxxxxx 31 characters xxxxxxxx" }
        specify do
          expect { Account.new(:identifier => identifier) }.to_not raise_error
        end
      end

      context "given an identifier 32 characters in length" do
        let(:identifier) { "xxxxxxxx 32 characters xxxxxxxxx" }
        specify do
          expect { Account.new(:identifier => identifier) }.to raise_error AccountIdentifierTooLongError, /'#{identifier}'/
        end
      end
    end

    describe Account::Instance do
      it "is sortable" do
        account = Account.new(:identifier => "savings", :scope_identifier => identity_scope)
        a = Account::Instance.new(:account => account, :scope => "123")
        b = Account::Instance.new(:account => account, :scope => "456")
        expect([b, a].sort).to eq [a, b]
      end

      it "is hashable" do
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
          its(:first) { should be_an Account }
          its("first.identifier") { should eq "savings" }
        end
      end
    end
  end
end
