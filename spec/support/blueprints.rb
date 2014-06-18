class UserBlueprint < Machinist::ActiveRecord::Blueprint
  def make!(attributes = {})
    savings_balance = attributes.delete(:savings_balance)
    checking_balance = attributes.delete(:checking_balance)
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
    user
  end
end

class User < ActiveRecord::Base
  self.table_name = "double_entry_users"
  def self.blueprint_class
    UserBlueprint
  end
end

User.blueprint do
  username { "user#{sn}" }
end
