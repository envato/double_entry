# encoding: utf-8
module DoubleEntry::Validation
 RSpec.describe LineCheck do

  describe '#last' do

    context 'Given some checks have been created' do
      before do
        Timecop.freeze 3.minutes.ago do
          LineCheck.create! :last_line_id => 100, :errors_found => false, :log => ''
        end
        Timecop.freeze 1.minute.ago do
          LineCheck.create! :last_line_id => 300, :errors_found => false, :log => ''
        end
        Timecop.freeze 2.minutes.ago do
          LineCheck.create! :last_line_id => 200, :errors_found => false, :log => ''
        end
      end

      it 'should find the newest LineCheck created (by creation_date)' do
        expect(LineCheck.last.last_line_id).to eq 300
      end
    end

  end

  describe '#perform!' do
    subject(:performed_line_check) { LineCheck.perform! }

    context 'Given a user with 100 dollars' do
      before { User.make!(:savings_balance => Money.new(100_00)) }

      context 'And all is consistent' do

        context 'And all lines have been checked' do
          before { LineCheck.perform!  }

          it { should be_nil }

          it 'should not persist a new LineCheck' do
            expect {
              LineCheck.perform!
            }.to_not change { LineCheck.count }
          end
        end

        it { should be_instance_of LineCheck }
        its(:errors_found) { should eq false }

        it 'should persist the LineCheck' do
          line_check = LineCheck.perform!
          expect(LineCheck.last).to eq line_check
        end
      end

      context 'And there is a consistency error in lines' do
        before { DoubleEntry::Line.order(:id).limit(1).update_all('balance = balance + 1') }

        its(:errors_found) { should be true }
        its(:log) { should match(/Error on line/) }

        it 'should correct the running balance' do
          expect {
            LineCheck.perform!
          }.to change { DoubleEntry::Line.order(:id).first.balance }.by Money.new(-1)
        end
      end

      context 'And there is a consistency error in account balance' do
        before { DoubleEntry::AccountBalance.order(:id).limit(1).update_all('balance = balance + 1') }

        its(:errors_found) { should be true }

        it 'should correct the account balance' do
          expect {
            LineCheck.perform!
          }.to change { DoubleEntry::AccountBalance.order(:id).first.balance }.by Money.new(-1)
        end
      end
    end


    context 'Given a user with a non default currency balance' do
      before { User.make!(:bitcoin_balance => Money.new(100_00, 'BTC')) }
      its(:errors_found) { should eq false }
      context 'And there is a consistency error in lines' do
        before { DoubleEntry::Line.order(:id).limit(1).update_all('balance = balance + 1') }

        its(:errors_found) { should eq true }
        it 'should correct the running balance' do
          expect {
            LineCheck.perform!
          }.to change { DoubleEntry::Line.order(:id).first.balance }.by Money.new(-1, 'BTC')
        end
      end
    end

    it "has a table name prefixed with double_entry_" do
      expect(LineCheck.table_name).to eq "double_entry_line_checks"
    end

  end
 end
end
