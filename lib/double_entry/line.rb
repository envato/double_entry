# encoding: utf-8

module DoubleEntry

  # This is the table to end all tables!
  #
  # Every financial transaction gets two entries in here: one for the source
  # account, and one for the destination account. Normal double-entry
  # accounting principles are followed.
  #
  # This is a log table, and should (ideally) never be updated.
  #
  # ## Indexes
  #
  # The indexes on this table are carefully chosen, as it's both big and heavily loaded.
  #
  # ### lines_scope_account_id_idx
  #
  # ```sql
  # ADD INDEX `lines_scope_account_id_idx` (scope, account, id)
  # ```
  #
  # This is the important one. It's used primarily for querying the current
  # balance of an account. eg:
  #
  # ```sql
  # SELECT * FROM `lines` WHERE scope = ? AND account = ? ORDER BY id DESC LIMIT 1
  # ```
  #
  # ### lines_scope_account_created_at_idx
  # 
  # ```sql
  # ADD INDEX `lines_scope_account_created_at_idx` (scope, account, created_at)
  # ```
  #
  # Used for querying historic balances:
  #
  # ```sql
  # SELECT * FROM `lines` WHERE scope = ? AND account = ? AND created_at < ? ORDER BY id DESC LIMIT 1
  # ```
  #
  # And for reporting on account changes over a time period:
  #
  # ```sql
  # SELECT SUM(amount) FROM `lines` WHERE scope = ? AND account = ? AND created_at BETWEEN ? AND ?
  # ```
  #
  # ### lines_account_created_at_idx and lines_account_code_created_at_idx
  #
  # ```sql
  # ADD INDEX `lines_account_created_at_idx` (account, created_at);
  # ADD INDEX `lines_account_code_created_at_idx` (account, code, created_at);
  # ```
  #
  # These two are used for generating reports, which need to sum things
  # by account, or account and code, over a particular period.
  #
  class Line < ActiveRecord::Base
    extend EncapsulateAsMoney

    belongs_to :detail, :polymorphic => true
    before_save :check_balance_will_not_be_sent_negative

    encapsulate_as_money :amount, :balance

    def code=(code)
      self[:code] = code.try(:to_s)
      code
    end

    def code
      self[:code].try(:to_sym)
    end

    def meta=(meta)
      self[:meta] = Marshal.dump(meta)
      meta
    end

    def meta
      meta = self[:meta]
      meta ? Marshal.load(meta) : {}
    end

    def account=(account)
      self[:account] = account.identifier.to_s
      self.scope = account.scope_identity
      account
    end

    def account
      DoubleEntry.account(self[:account].to_sym, :scope => scope)
    end

    def partner_account=(partner_account)
      self[:partner_account] = partner_account.identifier.to_s
      self.partner_scope = partner_account.scope_identity
      partner_account
    end

    def partner_account
      DoubleEntry.account(self[:partner_account].to_sym, :scope => partner_scope)
    end

    def partner
      self.class.find(partner_id)
    end

    def pair
      if decrease?
        [self, partner]
      else
        [partner, self]
      end
    end

    def decrease?
      amount < Money.empty
    end

    def increase?
      amount > Money.empty
    end

    # Query out just the id and created_at fields for lines, without
    # instantiating any ActiveRecord objects.
    def self.find_id_and_created_at(options)
      connection.select_rows <<-SQL
        SELECT id, created_at FROM #{Line.quoted_table_name} #{options[:joins]}
         WHERE #{sanitize_sql_for_conditions(options[:conditions])}
      SQL
    end

    private

    def check_balance_will_not_be_sent_negative
      if self.account.positive_only and self.balance < Money.new(0)
        raise AccountWouldBeSentNegative.new(account)
      end
    end
  end

end
