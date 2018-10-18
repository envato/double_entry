ActiveRecord::Schema.define do
  self.verbose = false

  create_table "double_entry_account_balances", :force => true do |t|
    t.string     "account", :null => false
    t.string     "scope"
    t.bigint     "balance", :null => false
    t.timestamps            :null => false
  end

  add_index "double_entry_account_balances", ["account"],          :name => "index_account_balances_on_account"
  add_index "double_entry_account_balances", ["scope", "account"], :name => "index_account_balances_on_scope_and_account", :unique => true

  create_table "double_entry_lines", :force => true do |t|
    t.string     "account",         :null => false
    t.string     "scope"
    t.string     "code",            :null => false
    t.bigint     "amount",          :null => false
    t.bigint     "balance",         :null => false
    t.references "partner",                         :index => false
    t.string     "partner_account", :null => false
    t.string     "partner_scope"
    t.references "detail",                          :index => false, :polymorphic => true
    t.timestamps                    :null => false
  end

  add_index "double_entry_lines", ["account", "code", "created_at", "partner_account"],  :name => "lines_account_code_created_at_partner_account_idx"
  add_index "double_entry_lines", ["account", "created_at"],                             :name => "lines_account_created_at_idx"
  add_index "double_entry_lines", ["scope", "account", "created_at"],                    :name => "lines_scope_account_created_at_idx"
  add_index "double_entry_lines", ["scope", "account", "id"],                            :name => "lines_scope_account_id_idx"

  create_table "double_entry_line_aggregates", :force => true do |t|
    t.string     "function",        :limit => 15, :null => false
    t.string     "account",                       :null => false
    t.string     "code"
    t.string     "partner_account"
    t.string     "scope"
    t.integer    "year"
    t.integer    "month"
    t.integer    "week"
    t.integer    "day"
    t.integer    "hour"
    t.bigint     "amount",                        :null => false
    t.string     "filter"
    t.string     "range_type",      :limit => 15, :null => false
    t.timestamps                                  :null => false
  end

  add_index "double_entry_line_aggregates", ["function", "account", "code", "partner_account", "year", "month", "week", "day"], :name => "line_aggregate_idx"

  create_table "double_entry_line_checks", :force => true do |t|
    t.references "last_line",    :null => false, :index => false
    t.boolean    "errors_found", :null => false
    t.text       "log"
    t.timestamps                 :null => false
  end

  add_index "double_entry_line_checks", ["created_at", "last_line_id"], :name => "line_checks_created_at_last_line_id_idx"

  create_table "double_entry_line_metadata", :force => true do |t|
    t.references "line",    :null => false, :index => false
    t.string     "key",     :null => false
    t.string     "value",   :null => false
    t.timestamps            :null => false
  end

  add_index "double_entry_line_metadata", ["line_id", "key", "value"], :name => "lines_meta_line_id_key_value_idx"

  # test table only
  create_table "users", :force => true do |t|
    t.string     "username", :null => false
    t.timestamps             :null => false
  end

  add_index "users", ["username"], :name => "index_users_on_username", :unique => true
end
