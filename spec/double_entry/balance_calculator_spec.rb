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
      expect(DoubleEntry::BalanceCalculator).to have_received(:new).with(anything, anything, anything, anything, anything, ['code1', 'code2', 'code'])
    end
  end

  describe '#calculate' do
    let(:scope) { nil }
    let(:from) { nil }
    let(:to) { nil }
    let(:at) { nil }
    let(:codes) { nil }

    subject(:calculator) { DoubleEntry::BalanceCalculator.new(account, scope, from, to, at, codes) }

    context 'with a scope specified' do

    end
  end
end
