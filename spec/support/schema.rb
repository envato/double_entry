ActiveRecord::Schema.define do
  self.verbose = false

  create_table "double_entry_account_balances", :force => true do |t|
    t.integer    "balance"
    t.string     "account", :limit => 31, :null => false
    t.string     "scope"
    t.timestamps
  end

  add_index "double_entry_account_balances", ["account"],          :name => "index_account_balances_on_account"
  add_index "double_entry_account_balances", ["scope", "account"], :name => "index_account_balances_on_scope_and_account", :unique => true

  create_table "double_entry_lines", :force => true do |t|
    t.integer    "amount"
    t.integer    "balance"
    t.integer    "partner_id"
    t.string     "code"
    t.string     "account",         :limit => 31, :null => false
    t.string     "scope"
    t.string     "partner_account", :limit => 31, :null => false
    t.string     "partner_scope"
    t.timestamps
    t.integer    "detail_id"
    t.string     "detail_type"
  end

  add_index "double_entry_lines", ["account", "code", "created_at"],  :name => "lines_account_code_created_at_idx"
  add_index "double_entry_lines", ["account", "created_at"],          :name => "lines_account_created_at_idx"
  add_index "double_entry_lines", ["scope", "account", "created_at"], :name => "lines_scope_account_created_at_idx"
  add_index "double_entry_lines", ["scope", "account", "id"],         :name => "lines_scope_account_id_idx"

  create_table "double_entry_line_aggregates", :force => true do |t|
    t.string     "function"
    t.string     "account",    :limit => 31, :null => false
    t.string     "code"
    t.string     "scope"
    t.integer    "year"
    t.integer    "month"
    t.integer    "week"
    t.integer    "day"
    t.integer    "hour"
    t.integer    "amount"
    t.timestamps
    t.string     "filter"
    t.string     "range_type"
  end

  add_index "double_entry_line_aggregates", ["function", "account", "code", "year", "month", "week", "day"], :name => "line_aggregate_idx"

  create_table "double_entry_line_checks", :force => true do |t|
    t.integer    "last_line_id"
    t.boolean    "errors_found"
    t.timestamps
    t.text       "log"
  end

  # test table only
  create_table "users", :force => true do |t|
    t.string     "username", :null => false
    t.timestamps
  end

  add_index "users", ["username"], :name => "index_users_on_username", :unique => true
end
