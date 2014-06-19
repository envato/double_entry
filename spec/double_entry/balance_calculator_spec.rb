# encoding: utf-8
require 'spec_helper'

describe DoubleEntry::BalanceCalculator do
  describe '.calculate' do
    let(:calculator) { double(:calculate => double) }
    let(:a_hash) { {} }

    before { allow(DoubleEntry::BalanceCalculator).to receive(:new).and_return(calculator) }

    it 'delegates to an instance' do
      DoubleEntry::BalanceCalculator.calculate(anything, a_hash)
      expect(calculator).to have_received(:calculate)
    end

    it 'compacts codes and code into a single array' do
      DoubleEntry::BalanceCalculator.calculate(anything, {:code => 'code', :codes => ['code1', 'code2']})
      expect(DoubleEntry::BalanceCalculator).to have_received(:new).with(
        anything, anything, anything, anything, anything, ['code1', 'code2', 'code']
      )
    end
  end

  describe '#calculate' do
    let(:account) { double.as_null_object }
    let(:scope) { nil }
    let(:from) { nil }
    let(:to) { nil }
    let(:at) { nil }
    let(:codes) { nil }

    let(:relation) { double.as_null_object }

    subject(:calculator) { DoubleEntry::BalanceCalculator.new(account, scope, from, to, at, codes) }

    before do
      allow(DoubleEntry::Line).to receive(:where).and_return(relation)
      allow(relation).to receive(:where).and_return(relation)
      calculator.calculate
    end

    context 'when the given account is a symbol' do
      let(:account) { :account }

      it 'scopes lines fetched by the account symbol' do
        expect(DoubleEntry::Line).to have_received(:where).with(:account => 'account')
      end

      context 'with a scopeable entity provided' do
        let(:scope) { double(:id => 'scope') }

        it 'scopes the lines fetched by the scope of the scopeable entity...scope' do
          expect(relation).to have_received(:where).with(:scope => 'scope')
        end
      end

      context 'with no scope provided' do
        it 'does not scope the lines fetched by the given scope' do
          expect(relation).to_not have_received(:where).with(:scope => 'scope')
        end
      end
    end

    context 'when the given account is DoubleEntry::Account-like' do
      let(:account) do
        DoubleEntry::Account::Instance.new(
          :account => DoubleEntry::Account.new(
                        :identifier => 'account_identity',
                        :scope_identifier => lambda { |scope_id| scope_id },
                      ),
          :scope   => 'account_scope_identity'
        )
      end

      it 'scopes the lines fetched by the accounts identifier and its scope identity' do
        expect(DoubleEntry::Line).to have_received(:where).with(:account => 'account_identity')
        expect(relation).to have_received(:where).with(:scope => 'account_scope_identity')
      end
    end
  end
end
