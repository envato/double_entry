# encoding: utf-8
require_relative 'blueprints'
DoubleEntry.configure do |config|

  # A set of accounts to test with
  config.define_accounts do |accounts|
    user_scope = accounts.active_record_scope_identifier(User)
    accounts.define(:identifier => :savings,  :scope_identifier => user_scope, :positive_only => true)
    accounts.define(:identifier => :checking, :scope_identifier => user_scope, :positive_only => true)
    accounts.define(:identifier => :test,     :scope_identifier => user_scope)
  end

  # A set of allowed transfers between accounts
  config.define_transfers do |transfers|
    transfers.define(:from => :test, :to => :savings,  :code => :bonus)
    transfers.define(:from => :test, :to => :checking, :code => :pay)
  end

end
