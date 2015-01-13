# encoding: utf-8
RSpec.describe DoubleEntry::AccountBalance do

  it "has a table name prefixed with double_entry_" do
    expect(DoubleEntry::AccountBalance.table_name).to eq "double_entry_account_balances"
  end
end
