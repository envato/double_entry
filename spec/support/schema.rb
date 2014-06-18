ActiveRecord::Schema.define do
  self.verbose = false

  create_table "account_balances", :force => true do |t|
    t.string   "account",    :null => false
    t.string   "scope"
    t.integer  "balance"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "account_balances", ["account"], :name => "index_account_balances_on_account"
  add_index "account_balances", ["scope", "account"], :name => "index_account_balances_on_scope_and_account", :unique => true

  create_table "lines", :force => true do |t|
    t.string   "account"
    t.string   "scope"
    t.string   "code"
    t.integer  "amount"
    t.integer  "balance"
    t.integer  "partner_id"
    t.string   "partner_account"
    t.string   "partner_scope"
    t.string   "meta"
    t.integer  "detail_id"
    t.string   "detail_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "lines", ["account", "code", "created_at"], :name => "lines_account_code_created_at_idx"
  add_index "lines", ["account", "created_at"], :name => "lines_account_created_at_idx"
  add_index "lines", ["scope", "account", "created_at"], :name => "lines_scope_account_created_at_idx"
  add_index "lines", ["scope", "account", "id"], :name => "lines_scope_account_id_idx"

  create_table "line_aggregates", :force => true do |t|
    t.string   "function"
    t.string   "account"
    t.string   "code"
    t.string   "scope"
    t.integer  "year"
    t.integer  "month"
    t.integer  "week"
    t.integer  "day"
    t.integer  "hour"
    t.integer  "amount"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "filter"
    t.string   "range_type"
  end

  add_index "line_aggregates", ["function", "account", "code", "year", "month", "week", "day"], :name => "line_aggregate_idx"

  create_table "line_checks", :force => true do |t|
    t.integer  "last_line_id"
    t.boolean  "errors_found"
    t.text     "log"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  # test table only
  create_table "users", :force => true do |t|
    t.string   "username"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "users", ["username"], :name => "index_users_on_username", :unique => true
end
