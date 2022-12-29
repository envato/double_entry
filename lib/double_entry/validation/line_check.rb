# encoding: utf-8
require 'set'

module DoubleEntry
  module Validation
    class LineCheck < ActiveRecord::Base

      def self.last_line_id_checked
        order('created_at DESC').limit(1).pluck(:last_line_id).first || 0
      end

      def self.perform!(fixer: nil)
        new.perform(fixer: fixer)
      end

      def perform(fixer: nil)
        log = ''
        current_line_id = nil

        active_accounts    = Set.new
        incorrect_accounts = Set.new

        new_lines_since_last_run.find_each do |line|
          incorrect_accounts << line.account unless running_balance_correct?(line, log)
          active_accounts << line.account
          current_line_id = line.id
        end

        active_accounts.each do |account|
          incorrect_accounts << account unless cached_balance_correct?(account, log)
        end

        incorrect_accounts.each(&fixer.method(:recalculate_account)) if fixer

        unless active_accounts.empty?
          LineCheck.create!(
            errors_found: incorrect_accounts.any?,
            last_line_id: current_line_id,
            log:          log,
          )
        end
      end

    private

      def new_lines_since_last_run
        Line.with_id_greater_than(LineCheck.last_line_id_checked)
      end

      def running_balance_correct?(line, log)
        previous_line = find_previous_line(line.account.identifier.to_s, line.scope, line.id)

        previous_balance = previous_line.length == 1 ? previous_line[0].balance : Money.zero(line.account.currency)

        if line.balance != (line.amount + previous_balance)
          log << line_error_message(line, previous_line, previous_balance)
        end

        line.balance == previous_balance + line.amount
      end

      def find_previous_line(identifier, scope, id)
        # yes, it needs to be find_by_sql, because any other find will be affected
        # by the find_each call in perform!

        if scope.nil?
          Line.find_by_sql([<<-SQL, identifier, id])
            SELECT * FROM #{Line.quoted_table_name} #{force_index}
            WHERE account = ?
            AND scope IS NULL
            AND id < ?
            ORDER BY id DESC
            LIMIT 1
          SQL
        else
          Line.find_by_sql([<<-SQL, identifier, scope, id])
          SELECT * FROM #{Line.quoted_table_name} #{force_index}
          WHERE account = ?
          AND scope = ?
          AND id < ?
          ORDER BY id DESC
          LIMIT 1
          SQL
        end
      end

      def force_index
        # Another work around for the MySQL 5.1 query optimiser bug that causes the ORDER BY
        # on the query to fail in some circumstances, resulting in an old balance being
        # returned. This was biting us intermittently in spec runs.
        # See http://bugs.mysql.com/bug.php?id=51431
        return '' unless Line.connection.adapter_name.match(/mysql/i)

        'FORCE INDEX (lines_scope_account_id_idx)'
      end

      def line_error_message(line, previous_line, previous_balance)
        <<-END_OF_MESSAGE.strip_heredoc
        *********************************
        Error on line ##{line.id}: balance:#{line.balance} != #{previous_balance} + #{line.amount}
        *********************************
          #{previous_line.inspect}
          #{line.inspect}

        END_OF_MESSAGE
      end

      def cached_balance_correct?(account, log)
        DoubleEntry.lock_accounts(account) do
          cached_balance = AccountBalance.find_by_account(account).balance
          running_balance = account.balance
          correct = (cached_balance == running_balance)
          log << <<~MESSAGE unless correct
            *********************************
            Error on account #{account}: #{cached_balance} (cached balance) != #{running_balance} (running balance)
            *********************************

          MESSAGE
          return correct
        end
      end
    end
  end
end
