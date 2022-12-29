# frozen_string_literal: true

module DoubleEntry
  module Validation
    class AccountFixer
      def recalculate_account(account)
        DoubleEntry.lock_accounts(account) do
          recalculated_balance = Money.zero(account.currency)

          lines_for_account(account).each do |line|
            recalculated_balance += line.amount
            if line.balance != recalculated_balance
              line.update_attribute(:balance, recalculated_balance)
            end
          end

          update_balance_for_account(account, recalculated_balance)
        end
      end

      private

      def lines_for_account(account)
        Line.where(
          account: account.identifier.to_s,
          scope: account.scope_identity&.to_s
        ).order(:id)
      end

      def update_balance_for_account(account, balance)
        account_balance = Locking.balance_for_locked_account(account)
        account_balance.update_attribute(:balance, balance)
      end
    end
  end
end
