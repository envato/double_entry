# encoding: utf-8
RSpec.describe DoubleEntry::AccountBalance do
  describe '.table_name' do
    subject { DoubleEntry::AccountBalance.table_name }
    it { should eq('double_entry_account_balances') }
  end
end
