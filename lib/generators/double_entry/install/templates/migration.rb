class CreateDoubleEntryTables < ActiveRecord::Migration<%= migration_version %>
  def self.up
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
      <%- if json_metadata -%>
      if ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
        t.jsonb "metadata"
      else
        t.json "metadata"
      end
      <%- end -%>
      t.timestamps                    :null => false
    end

    add_index "double_entry_lines", ["account", "code", "created_at"],  :name => "lines_account_code_created_at_idx"
    add_index "double_entry_lines", ["account", "created_at"],          :name => "lines_account_created_at_idx"
    add_index "double_entry_lines", ["scope", "account", "created_at"], :name => "lines_scope_account_created_at_idx"
    add_index "double_entry_lines", ["scope", "account", "id"],         :name => "lines_scope_account_id_idx"

    create_table "double_entry_line_checks", :force => true do |t|
      t.references "last_line",    :null => false, :index => false
      t.boolean    "errors_found", :null => false
      t.text       "log"
      t.timestamps                 :null => false
    end

    add_index "double_entry_line_checks", ["created_at", "last_line_id"], :name => "line_checks_created_at_last_line_id_idx"
    <%- unless json_metadata -%>

    create_table "double_entry_line_metadata", :force => true do |t|
      t.references "line",    :null => false, :index => false
      t.string     "key",     :null => false
      t.string     "value",   :null => false
      t.timestamps            :null => false
    end

    add_index "double_entry_line_metadata", ["line_id", "key", "value"], :name => "lines_meta_line_id_key_value_idx"
    <%- end -%>
  end

  def self.down
    drop_table "double_entry_line_metadata" if table_exists?("double_entry_line_metadata")
    drop_table "double_entry_line_checks"
    drop_table "double_entry_lines"
    drop_table "double_entry_account_balances"
  end
end
