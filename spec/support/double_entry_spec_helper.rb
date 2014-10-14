# encoding: utf-8
module DoubleEntrySpecHelper

  def lines_for_account(account)
    lines = DoubleEntry::Line.order(:id)
    lines = lines.where(:scope => account.scope_identity) if account.scoped?
    lines = lines.where(:account => account.identifier.to_s)
    lines
  end

  def perform_deposit(user, amount)
    DoubleEntry.transfer(Money.new(amount),
      :from => DoubleEntry.account(:test, :scope => user),
      :to   => DoubleEntry.account(:savings, :scope => user),
      :code => :bonus,
    )
  end

  def perform_btc_deposit(user, amount)
    DoubleEntry.transfer(Money.new(amount, :btc),
      :from => DoubleEntry.account(:btc_test, :scope => user),
      :to   => DoubleEntry.account(:btc_savings, :scope => user),
      :code => :btc_test_transfer,
    )
  end

end
