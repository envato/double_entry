# encoding: utf-8
module DoubleEntry
  RSpec.describe Account do
    let(:identity_scope) { ->(value) { value } }

    describe '::new' do
      context 'given a account_identifier_max_length of 31' do
        before { Account.account_identifier_max_length = 31 }
        after { Account.account_identifier_max_length = nil }

        context 'given an identifier 31 characters in length' do
          let(:identifier) { 'xxxxxxxx 31 characters xxxxxxxx' }
          specify do
            expect { Account.new(identifier: identifier) }.to_not raise_error
          end
        end

        context 'given an identifier 32 characters in length' do
          let(:identifier) { 'xxxxxxxx 32 characters xxxxxxxxx' }
          specify do
            expect { Account.new(identifier: identifier) }.to raise_error AccountIdentifierTooLongError, /'#{identifier}'/
          end
        end
      end
    end

    describe Account::Instance do
      it 'is sortable' do
        account = Account.new(identifier: 'savings', scope_identifier: identity_scope)
        a = Account::Instance.new(account: account, scope: '123')
        b = Account::Instance.new(account: account, scope: '456')
        expect([b, a].sort).to eq [a, b]
      end

      it 'is hashable' do
        account = Account.new(identifier: 'savings', scope_identifier: identity_scope)
        a1 = Account::Instance.new(account: account, scope: '123')
        a2 = Account::Instance.new(account: account, scope: '123')
        b  = Account::Instance.new(account: account, scope: '456')

        expect(a1.hash).to eq a2.hash
        expect(a1.hash).to_not eq b.hash
      end

      describe '::new' do
        let(:account) { Account.new(identifier: 'x', scope_identifier: identity_scope) }
        subject(:initialize_account_instance) { Account::Instance.new(account: account, scope: scope) }

        context 'given a scope_identifier_max_length of 23' do
          before { Account.scope_identifier_max_length = 23 }
          after { Account.scope_identifier_max_length = nil }

          context 'given a scope identifier 23 characters in length' do
             let(:scope) { 'xxxx 23 characters xxxx' }
             specify { expect { initialize_account_instance }.to_not raise_error }
           end

          context 'given a scope identifier 24 characters in length' do
            let(:scope) { 'xxxx 24 characters xxxxx' }
            specify { expect { initialize_account_instance }.to raise_error ScopeIdentifierTooLongError, /'#{scope}'/ }
          end
        end
      end
    end

    describe 'currency' do
      it 'defaults to USD currency' do
        account = DoubleEntry::Account.new(identifier: 'savings', scope_identifier: identity_scope)
        expect(DoubleEntry::Account::Instance.new(account: account).currency).to eq('USD')
      end

      it 'allows the currency to be set' do
        account = DoubleEntry::Account.new(identifier: 'savings', scope_identifier: identity_scope, currency: 'AUD')
        expect(DoubleEntry::Account::Instance.new(account: account).currency).to eq('AUD')
      end
    end

    describe Account::Set do
      subject(:set) { described_class.new }

      describe '#find' do
        before do
          set.define(identifier: :savings)
          set.define(identifier: :checking, scope_identifier: ar_class)
        end

        let(:ar_class) { double(:ar_class) }

        it 'finds unscoped accounts' do
          expect(set.find(:savings, false)).to be_an Account
          expect(set.find(:savings, false).identifier).to eq :savings

          expect { set.find(:savings, true) }.to raise_error(UnknownAccount)
        end

        it 'finds scoped accounts' do
          expect(set.find(:checking, true)).to be_an Account
          expect(set.find(:checking, true).identifier).to eq :checking

          expect { set.find(:checking, false) }.to raise_error(UnknownAccount)
        end
      end
    end
  end
end
