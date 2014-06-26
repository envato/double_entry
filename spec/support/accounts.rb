# encoding: utf-8
user_scope = lambda do |user_identifier|
  if user_identifier.is_a?(User)
    user_identifier.id
  else
    user_identifier
  end
end

DoubleEntry.configure do |config|

  # A set of accounts to test with
  config.define_accounts do |accounts|
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
