class UserBlueprint < Machinist::ActiveRecord::Blueprint
  def make!(attributes = {})
    savings_balance = attributes.delete(:savings_balance)
    checking_balance = attributes.delete(:checking_balance)
    bitcoin_balance = attributes.delete(:bitcoin_balance)
    user = super(attributes)
    if savings_balance
      DoubleEntry.transfer(
        savings_balance,
        :from => DoubleEntry.account(:test, :scope => user),
        :to   => DoubleEntry.account(:savings, :scope => user),
        :code => :bonus,
      )
    end
    if checking_balance
      DoubleEntry.transfer(
        checking_balance,
        :from => DoubleEntry.account(:test, :scope => user),
        :to   => DoubleEntry.account(:checking, :scope => user),
        :code => :pay,
      )
    end
    if bitcoin_balance
      DoubleEntry.transfer(
        bitcoin_balance,
        :from => DoubleEntry.account(:btc_test, :scope => user),
        :to   => DoubleEntry.account(:btc_savings, :scope => user),
        :code => :btc_test_transfer,
      )
    end
    user
  end
end

class User < ActiveRecord::Base
  def self.blueprint_class
    UserBlueprint
  end
end

User.blueprint do
  username { "user#{sn}" }
end
