# encoding: utf-8
require_relative 'blueprints'
DoubleEntry.configure do |config|

  # A set of accounts to test with
  config.define_accounts do |accounts|
    user_scope = accounts.active_record_scope_identifier(User)
    accounts.define(:identifier => :savings,     :scope_identifier => user_scope, :positive_only => true)
    accounts.define(:identifier => :checking,    :scope_identifier => user_scope, :positive_only => true)
    accounts.define(:identifier => :test,        :scope_identifier => user_scope)
    accounts.define(:identifier => :btc_test,    :scope_identifier => user_scope, :currency => "BTC")
    accounts.define(:identifier => :btc_savings, :scope_identifier => user_scope, :currency => "BTC")

    accounts.define(:identifier => :a_positive_only_acc, :scope_identifier => user_scope, :positive_only => true)
    accounts.define(:identifier => :a_negative_only_acc, :scope_identifier => user_scope, :negative_only => true)
  end

  # A set of allowed transfers between accounts
  config.define_transfers do |transfers|
    transfers.define(:from => :test,     :to => :savings,     :code => :bonus)
    transfers.define(:from => :test,     :to => :checking,    :code => :pay)
    transfers.define(:from => :savings,  :to => :test,        :code => :test_withdrawal)
    transfers.define(:from => :btc_test, :to => :btc_savings, :code => :btc_test_transfer)
  end

end
