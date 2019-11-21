# encoding: utf-8
module DoubleEntry
  RSpec.describe Transfer do
    describe '::new' do
      context 'given a code_max_length of 47' do
        before { Transfer.code_max_length = 47 }
        after { Transfer.code_max_length = nil }

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
    end

    describe '::transfer' do
      let(:amount)  { Money.new(10_00) }
      let(:user)    { create(:user) }
      let(:test)    { DoubleEntry.account(:test, :scope => user) }
      let(:savings) { DoubleEntry.account(:savings, :scope => user) }
      let(:new_lines) { Line.all[-2..-1] }

      subject(:transfer) { Transfer.transfer(amount, options) }

      context 'without metadata' do
        let(:options) { { :from => test, :to => savings, :code => :bonus } }

        it 'creates lines' do
          expect { transfer }.to change { Line.count }.by 2
        end

        context 'with config.json_metadata = true', skip: ActiveRecord.version.version < '5' do
          around do |example|
            DoubleEntry.config.json_metadata = true
            example.run
            DoubleEntry.config.json_metadata = false
          end

          it 'does not create metadata lines' do
            expect { transfer }.not_to change { LineMetadata.count }
          end

          it 'does not attach metadata to the lines' do
            transfer
            new_lines.each do |line|
              expect(line.metadata).to be_blank
            end
          end
        end

        context 'with config.json_metadata = false' do
          it 'does not create metadata lines' do
            expect { transfer }.not_to change { LineMetadata.count }
          end

          it 'does not attach metadata to the lines', skip: ActiveRecord.version.version < '5' do
            transfer
            new_lines.each do |line|
              expect(line.metadata).to be_blank
            end
          end
        end
      end

      context 'with metadata' do
        let(:options) { { :from => test, :to => savings, :code => :bonus, :metadata => { :country => 'AU', :tax => 'GST' } } }

        context 'with config.json_metadata = true', skip: ActiveRecord.version.version < '5' do
          around do |example|
            DoubleEntry.config.json_metadata = true
            example.run
            DoubleEntry.config.json_metadata = false
          end

          it 'does not create metadata lines' do
            expect { transfer }.not_to change { LineMetadata.count }
          end

          it 'stores the first key/value pair' do
            transfer
            expect(new_lines.count { |line| line.metadata['country'] == 'AU' }).to be 2
          end

          it 'stores another key/value pair' do
            transfer
            expect(new_lines.count { |line| line.metadata['tax'] == 'GST' }).to be 2
          end
        end

        context 'with config.json_metadata = false' do
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

          it 'does not attach metadata to the lines', skip: ActiveRecord.version.version < '5' do
            transfer
            new_lines.each do |line|
              expect(line.metadata).to be_blank
            end
          end
        end
      end

      context 'metadata with multiple values in array for one key' do
        let(:options) { { :from => test, :to => savings, :code => :bonus, :metadata => { :tax => ['GST', 'VAT'] } } }

        context 'with config.json_metadata = true', skip: ActiveRecord.version.version < '5' do
          around do |example|
            DoubleEntry.config.json_metadata = true
            example.run
            DoubleEntry.config.json_metadata = false
          end

          it 'does not create metadata lines' do
            expect { transfer }.not_to change { LineMetadata.count }
          end

          it 'stores both values to the same key' do
            transfer
            expect(new_lines.count { |line| line.metadata['tax'] == ['GST', 'VAT'] }).to be 2
          end
        end

        context 'with config.json_metadata = false' do
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

          it 'does not attach metadata to the lines', skip: ActiveRecord.version.version < '5' do
            transfer
            new_lines.each do |line|
              expect(line.metadata).to be_blank
            end
          end
        end
      end
    end

    describe Transfer::Set do
      subject(:set) { described_class.new }

      before do
        set.define(
          :code => :transfer_code,
          :from => from_account.identifier,
          :to   => to_account.identifier,
        )

        set.define(
          :code => :another_transfer_code,
          :from => from_account.identifier,
          :to   => to_account.identifier,
        )
      end

      let(:from_account) { instance_double(Account, :identifier => :from) }
      let(:to_account)   { instance_double(Account, :identifier => :to) }

      describe '#find' do
        it 'finds the transfers' do
          first_transfer = set.find(from_account, to_account, :transfer_code)
          second_transfer = set.find(from_account, to_account, :another_transfer_code)

          expect(first_transfer).to be_a Transfer
          expect(first_transfer.code).to eq :transfer_code
          expect(first_transfer.from).to eq from_account.identifier
          expect(first_transfer.to).to eq to_account.identifier

          expect(second_transfer).to be_a Transfer
          expect(second_transfer.code).to eq :another_transfer_code
          expect(second_transfer.from).to eq from_account.identifier
          expect(second_transfer.to).to eq to_account.identifier
        end

        it 'returns nothing when searching for undefined transfers' do
          undefined_transfer = set.find(to_account, from_account, :transfer_code)

          expect(undefined_transfer).to eq nil
        end
      end

      describe '#find!' do
        it 'also finds the transfers' do
          first_transfer = set.find!(from_account, to_account, :transfer_code)
          second_transfer = set.find!(from_account, to_account, :another_transfer_code)

          expect(first_transfer).to be_a Transfer
          expect(first_transfer.code).to eq :transfer_code
          expect(first_transfer.from).to eq from_account.identifier
          expect(first_transfer.to).to eq to_account.identifier

          expect(second_transfer).to be_a Transfer
          expect(second_transfer.code).to eq :another_transfer_code
          expect(second_transfer.from).to eq from_account.identifier
          expect(second_transfer.to).to eq to_account.identifier
        end

        it 'raises an error when searching for undefined transfers' do
          expect { set.find!(to_account, from_account, :transfer_code) }
            .to raise_error(TransferNotAllowed)
        end
      end
    end
  end
end
