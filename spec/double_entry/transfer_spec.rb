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

    describe '::transfer' do
      let(:amount)  { Money.new(10_00) }
      let(:user)    { User.make! }
      let(:test)    { DoubleEntry.account(:test, :scope => user) }
      let(:savings) { DoubleEntry.account(:savings, :scope => user) }
      let(:new_lines) { Line.all[-2..-1] }

      subject(:transfer) { Transfer.transfer(amount, options) }

      context 'without metadata' do
        let(:options) { { :from => test, :to => savings, :code => :bonus } }

        it 'creates lines' do
          expect { transfer }.to change { Line.count }.by 2
        end

        it 'does not create metadata lines' do
          expect { transfer }.not_to change { LineMetadata.count }
        end
      end

      context 'with metadata' do
        let(:options) { { :from => test, :to => savings, :code => :bonus, :metadata => { :country => 'AU', :tax => 'GST' } } }
        let(:new_metadata) { LineMetadata.all[-4..-1] }

        it 'creates metadata lines' do
          expect { transfer }.to change { LineMetadata.count }.by 4
        end

        it 'associates the metadata lines with the transfer lines' do
          transfer
          expect(new_metadata.count { |meta| meta.line == new_lines.first }).to be 2
          expect(new_metadata.count { |meta| meta.line == new_lines.last }).to be 2
        end

        it 'stores the first key/value pair' do
          transfer
          countries = new_metadata.select { |meta| meta.key == :country }
          expect(countries.size).to be 2
          expect(countries.count { |meta| meta.value == 'AU' }).to be 2
        end

        it 'associates the first key/value pair with both lines' do
          transfer
          countries = new_metadata.select { |meta| meta.key == :country }
          expect(countries.map(&:line).uniq.size).to be 2
        end

        it 'stores another key/value pair' do
          transfer
          taxes = new_metadata.select { |meta| meta.key == :tax }
          expect(taxes.size).to be 2
          expect(taxes.count { |meta| meta.value == 'GST' }).to be 2
        end
      end

      context 'metadata with multiple values in array for one key' do
        let(:options) { { :from => test, :to => savings, :code => :bonus, :metadata => { :tax => ['GST', 'VAT'] } } }
        let(:new_metadata) { LineMetadata.all[-4..-1] }

        it 'creates metadata lines' do
          expect { transfer }.to change { LineMetadata.count }.by 4
        end

        it 'associates the metadata lines with the transfer lines' do
          transfer
          expect(new_metadata.count { |meta| meta.line == new_lines.first }).to be 2
          expect(new_metadata.count { |meta| meta.line == new_lines.last }).to be 2
        end

        it 'stores both values to the same key' do
          transfer
          taxes = new_metadata.select { |meta| meta.key == :tax }
          expect(taxes.size).to be 4
          expect(taxes.count { |meta| meta.value == 'GST' }).to be 2
          expect(taxes.map(&:line).uniq.size).to be 2
        end
      end
    end

    describe Transfer::Set do
      subject(:set) { described_class.new }

      describe '#find' do
        before do
          set.define(
            :code => :transfer_code,
            :from => from_account.identifier,
            :to   => to_account.identifier,
          )
        end

        let(:from_account) { instance_double(Account, :identifier => :from) }
        let(:to_account)   { instance_double(Account, :identifier => :to) }

        subject { set.find(from_account, to_account, :transfer_code) }

        it 'should find the transfer' do
          expect(subject).to be_a Transfer
          expect(subject.code).to eq :transfer_code
          expect(subject.from).to eq from_account.identifier
          expect(subject.to).to eq to_account.identifier
        end
      end
    end
  end
end
