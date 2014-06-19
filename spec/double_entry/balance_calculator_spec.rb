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
  end

  describe '#calculate' do

  end
end
