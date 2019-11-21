require 'double_entry'

DoubleEntry.configure do |config|
  # Use json(b) column in double_entry_lines table to store metadata instead of separate metadata table
  config.json_metadata = <%= json_metadata %>

  # config.define_accounts do |accounts|
  #   user_scope = ->(user) do
  #     raise 'not a User' unless user.class.name == 'User'
  #     user.id
  #   end
  #   accounts.define(:identifier => :savings,  :scope_identifier => user_scope, :positive_only => true)
  #   accounts.define(:identifier => :checking, :scope_identifier => user_scope)
  # end
  #
  # config.define_transfers do |transfers|
  #   transfers.define(:from => :checking, :to => :savings,  :code => :deposit)
  #   transfers.define(:from => :savings,  :to => :checking, :code => :withdraw)
  # end
end
