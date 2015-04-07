# encoding: utf-8
module DoubleEntry
  RSpec.describe Transfer do
    describe '::new' do
      context 'given a code 47 characters in length' do
        let(:code) { 'xxxxxxxxxxxxxxxx 47 characters xxxxxxxxxxxxxxxx' }
        specify do
          expect { Transfer.new(:code => code) }.to_not raise_error
        end
      end

      context 'given a code 48 characters in length' do
        let(:code) { 'xxxxxxxxxxxxxxxx 48 characters xxxxxxxxxxxxxxxxx' }
        specify do
          expect { Transfer.new(:code => code) }.to raise_error TransferCodeTooLongError, /'#{code}'/
        end
      end
    end

    describe Transfer::Set do
      describe '#define' do
        before do
          subject.define(
            :code => 'code',
            :from => double(:identifier => 'from'),
            :to => double(:identifier => 'to'),
          )
        end
        its(:first) { should be_a Transfer }
        its('first.code') { should eq 'code' }
        its('first.from.identifier') { should eq 'from' }
        its('first.to.identifier') { should eq 'to' }
      end
    end
  end
end
