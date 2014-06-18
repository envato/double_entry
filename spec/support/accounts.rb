# encoding: utf-8
# These make it easier to quickly set up account balances for testing.

# user scoping magic, accepts a User, Fixnum, or String
user_scope = lambda do |user_identifier|
  if user_identifier.is_a?(Fixnum) or user_identifier.is_a?(String)
    user_identifier
  elsif user_identifier.is_a?(User)
    user_identifier.id
  else
    raise "unknown type expected fixnum, string or user, got: #{user_identifier.inspect}"
  end
end

# A set of accounts to test with
DoubleEntry.accounts = DoubleEntry::Account::Set.new.tap do |accounts|
  accounts << DoubleEntry::Account.new(:identifier => :savings, :scope_identifier => user_scope, :positive_only => true)
  accounts << DoubleEntry::Account.new(:identifier => :checking, :scope_identifier => user_scope, :positive_only => true)
  accounts << DoubleEntry::Account.new(:identifier => :test, :scope_identifier => user_scope)
end

# A set of allowed transfers between accounts
DoubleEntry.transfers = DoubleEntry::Transfer::Set.new.tap do |transfers|
  transfers << DoubleEntry::Transfer.new(:from => :test, :to => :savings, :code => :bonus)
  transfers << DoubleEntry::Transfer.new(:from => :test, :to => :checking, :code => :pay)
end
