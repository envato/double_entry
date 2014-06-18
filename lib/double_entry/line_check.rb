# encoding: utf-8
require 'set'

module DoubleEntry
  class LineCheck < ActiveRecord::Base
    extend EncapsulateAsMoney

    default_scope -> { order('created_at') }

    def self.perform!
      new.perform
    end

    def perform
      log = ''

      active_accounts    = Set.new
      incorrect_accounts = Set.new

      line_id = nil
      DoubleEntry::Line.where('id > ?', last_run_line_id).find_each do |line|
        if !running_balance_correct?(line, log)
          incorrect_accounts << line.account
        end
        active_accounts << line.account
        line_id = line.id
      end

      active_accounts.each do |account|
        if !cached_balance_correct?(account)
          incorrect_accounts << account
        end
      end

      incorrect_accounts.each { |account| recalculate_account(account) }

      unless active_accounts.empty?
        errors_found = !incorrect_accounts.empty?

        DoubleEntry::LineCheck.create! :errors_found => errors_found, :log => log, :last_line_id => line_id
      end
    end

  private

    def last_run_line_id
      latest = DoubleEntry::LineCheck.last
      latest ? latest.last_line_id : 0
    end

    def running_balance_correct?(line, log)
      # Another work around for the MySQL 5.1 query optimiser bug that causes the ORDER BY
      # on the query to fail in some circumstances, resulting in an old balance being
      # returned. This was biting us intermittently in spec runs.
      # See http://bugs.mysql.com/bug.php?id=51431
      force_index = if DoubleEntry::Line.connection.adapter_name.match /mysql/i
                      "FORCE INDEX (lines_scope_account_id_idx)"
                    else
                      ""
                    end

      # yes, it needs to be find_by_sql, because any other find will be affected
      # by the find_in_batches call in perform!
      previous_line = DoubleEntry::Line.find_by_sql(["SELECT * FROM #{Line.quoted_table_name} #{force_index} WHERE account = ? AND scope = ? AND id < ? ORDER BY id DESC LIMIT 1", line.account.identifier.to_s, line.scope, line.id])
      previous_balance = previous_line.length == 1 ? previous_line[0].balance : Money.empty

      if line.balance != (line.amount + previous_balance)
        log << line_error_message(line, previous_line, previous_balance)
      end

      line.balance == previous_balance + line.amount
    end

    def line_error_message(line, previous_line, previous_balance)
      <<-END_OF_MESSAGE
        *********************************
        Error on line ##{line.id}: balance:#{line.balance} != #{previous_balance} + #{line.amount}
        *********************************
        #{previous_line.inspect}
        #{line.inspect}

      END_OF_MESSAGE
    end

    def cached_balance_correct?(account)
      DoubleEntry.lock_accounts(account) do
        return DoubleEntry::AccountBalance.find_by_account(account).balance == account.balance
      end
    end

    def recalculate_account(account)
      DoubleEntry.lock_accounts(account) do
        recalculated_balance = Money.empty

        lines_for_account(account).each do |line|
          recalculated_balance += line.amount
          line.update_attribute(:balance, recalculated_balance) if line.balance != recalculated_balance
        end

        update_balance_for_account(account, recalculated_balance)
      end
    end

    def lines_for_account(account)
      DoubleEntry::Line.where(
        :account => account.identifier.to_s,
        :scope   => account.scope_identity.to_s
      ).order(:id)
    end

    def update_balance_for_account(account, balance)
      account_balance = DoubleEntry::Locking.balance_for_locked_account(account)
      account_balance.update_attribute(:balance, balance)
    end
  end
end
