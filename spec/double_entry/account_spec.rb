# encoding: utf-8
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

      describe "::new" do
        let(:account) { Account.new(:identifier => "x", :scope_identifier => identity_scope) }
        subject(:initialize_account_instance) { Account::Instance.new(:account => account, :scope => scope) }

        context "given a scope identifier 23 characters in length" do
          let(:scope) { "xxxx 23 characters xxxx" }
          specify { expect { initialize_account_instance }.to_not raise_error }
        end

        context "given a scope identifier 24 characters in length" do
          let(:scope) { "xxxx 24 characters xxxxx" }
          specify { expect { initialize_account_instance }.to raise_error ScopeIdentifierTooLongError, /'#{scope}'/ }
        end
      end
    end

    describe "currency" do
      it "defaults to USD currency" do
        account = DoubleEntry::Account.new(:identifier => "savings", :scope_identifier => identity_scope)
        expect(DoubleEntry::Account::Instance.new(:account => account).currency).to eq("USD")
      end

      it "allows the currency to be set" do
        account = DoubleEntry::Account.new(:identifier => "savings", :scope_identifier => identity_scope, :currency => "AUD")
        expect(DoubleEntry::Account::Instance.new(:account => account).currency).to eq("AUD")
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

      describe "#active_record_scope_identifier" do
        subject(:scope) { Account::Set.new.active_record_scope_identifier(ar_class) }

        context "given ActiveRecordScopeFactory is stubbed" do
          let(:scope_identifier) { double(:scope_identifier) }
          let(:scope_factory) { double(:scope_factory, :scope_identifier => scope_identifier) }
          let(:ar_class) { double(:ar_class) }
          before { allow(Account::ActiveRecordScopeFactory).to receive(:new).with(ar_class).and_return(scope_factory) }

          it { should eq scope_identifier }
        end
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

          context "given differing model instance with ID 32" do
            let(:value) { double(:id => 32) }
            it "raises an error" do
              expect { scope_identifier.call(value) }.to raise_error DoubleEntry::AccountScopeMismatchError
            end
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
