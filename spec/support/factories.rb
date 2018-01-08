require 'factory_bot'

User = Class.new(ActiveRecord::Base)

FactoryBot.define do
  factory :user do
    username { "user#{__id__}" }

    transient do
      savings_balance false
      checking_balance false
      bitcoin_balance false
    end

    after(:create) do |user, evaluator|
      if evaluator.savings_balance
        DoubleEntry.transfer(
          evaluator.savings_balance,
          from: DoubleEntry.account(:test, scope: user),
          to:   DoubleEntry.account(:savings, scope: user),
          code: :bonus,
        )
      end
      if evaluator.checking_balance
        DoubleEntry.transfer(
          evaluator.checking_balance,
          from: DoubleEntry.account(:test, scope: user),
          to:   DoubleEntry.account(:checking, scope: user),
          code: :pay,
        )
      end
      if evaluator.bitcoin_balance
        DoubleEntry.transfer(
          evaluator.bitcoin_balance,
          from: DoubleEntry.account(:btc_test, scope: user),
          to:   DoubleEntry.account(:btc_savings, scope: user),
          code: :btc_test_transfer,
        )
      end
    end
  end
end

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
end
