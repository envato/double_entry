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

    belongs_to :detail, :polymorphic => true

    def amount
      self[:amount] && Money.new(self[:amount], currency)
    end

    def amount=(money)
      self[:amount] = (money && money.fractional)
    end

    def balance
      self[:balance] && Money.new(self[:balance], currency)
    end

    def balance=(money)
      self[:balance] = (money && money.fractional)
    end

    def save(*)
      check_balance_will_not_be_sent_negative
      super
    end

    def save!(*)
      check_balance_will_not_be_sent_negative
      super
    end

    def code=(code)
      self[:code] = code.try(:to_s)
      code
    end

    def code
      self[:code].try(:to_sym)
    end

    def account=(_account)
      self[:account] = _account.identifier.to_s
      self.scope = _account.scope_identity
      raise "Missing Account" unless account
      _account
    end

    def account
      if self[:account]
        DoubleEntry.account(self[:account].to_sym, :scope => scope)
      end
    end

    def currency
      account.currency if self[:account]
    end

    def partner_account=(_partner_account)
      self[:partner_account] = _partner_account.identifier.to_s
      self.partner_scope = _partner_account.scope_identity
      raise "Missing Partner Account" unless partner_account
      _partner_account
    end

    def partner_account
      if self[:partner_account]
        DoubleEntry.account(self[:partner_account].to_sym, :scope => partner_scope)
      end
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
      amount < Money.zero
    end

    def increase?
      amount > Money.zero
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
