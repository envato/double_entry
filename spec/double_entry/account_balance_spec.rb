# encoding: utf-8
RSpec.describe DoubleEntry::AccountBalance do
  describe '.table_name' do
    subject { DoubleEntry::AccountBalance.table_name }
    it { should eq('double_entry_account_balances') }
  end

  describe '.scopes_with_minimum_balance_for_account' do
    subject(:scopes) { DoubleEntry::AccountBalance.scopes_with_minimum_balance_for_account(minimum_balance, :checking) }

    context "a 'checking' account with balance $100" do
      let!(:user) { create(:user, :checking_balance => Money.new(100_00)) }

      context 'when searching for balance $99' do
        let(:minimum_balance) { Money.new(99_00) }
        it { should include user.id.to_s }
      end

      context 'when searching for balance $100' do
        let(:minimum_balance) { Money.new(100_00) }
        it { should include user.id.to_s }
      end

      context 'when searching for balance $101' do
        let(:minimum_balance) { Money.new(101_00) }
        it { should_not include user.id.to_s }
      end
    end
  end
end
