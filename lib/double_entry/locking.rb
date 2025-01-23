# encoding: utf-8
module DoubleEntry
  # Lock financial accounts to ensure consistency.
  #
  # In order to ensure financial transactions always keep track of balances
  # consistently, database-level locking is needed. This module takes care of
  # it.
  #
  # See DoubleEntry.lock_accounts and DoubleEntry.transfer for the public interface
  # to this stuff.
  #
  # Locking is done on DoubleEntry::AccountBalance records. If an AccountBalance
  # record for an account doesn't exist when you try to lock it, the locking
  # code will create one.
  #
  # script/jack_hammer can be used to run concurrency tests on double_entry to
  # validates that locking works properly.
  module Locking
    include Configurable

    class Configuration
      # Set this in your tests if you're using transactional_fixtures, so we know
      # not to complain about a containing transaction when you call lock_accounts.
      attr_accessor :running_inside_transactional_fixtures

      def initialize #:nodoc:
        @running_inside_transactional_fixtures = false
      end
    end

    # Run the passed in block in a transaction with the given accounts locked for update.
    #
    # The transaction must be the outermost transaction to ensure data integrity. A
    # LockMustBeOutermostTransaction will be raised if it isn't.
    def self.lock_accounts(*accounts, &block)
      lock = Lock.new(accounts)

      if lock.in_a_locked_transaction?
        lock.ensure_locked!
        block.call
      else
        lock.perform_lock(&block)
      end

    rescue ActiveRecord::StatementInvalid => exception
      if exception.message =~ /lock wait timeout/i
        raise LockWaitTimeout
      else
        raise
      end
    end

    # Return the account balance record for the given account name if there's a
    # lock on it, or raise a LockNotHeld if there isn't.
    def self.balance_for_locked_account(account)
      Lock.new([account]).balance_for(account)
    end

    class Lock
      @@locks = {}

      def initialize(accounts)
        # Make sure we always lock in the same order, to avoid deadlocks.
        @accounts = accounts.flatten.sort
      end

      # Start a transaction, grab locks on the given accounts, then call the block
      # from within the transaction.
      def perform_lock
        ensure_outermost_transaction! if DoubleEntry.config.retry_deadlocks

        # puts "restartable_transaction"
        AccountBalance.restartable_transaction do
          # puts "with_restart_on_deadlock"
          AccountBalance.with_restart_on_deadlock { grab_locks }
          begin
            # puts "yielding after locks..."
            yield
            # puts "finished yielding after locks..."
          ensure
            # puts "remove_locks"
            remove_locks
          end
        end
      end

      # Return true if we're inside a lock_accounts block.
      def in_a_locked_transaction?
        !locks.nil?
      end

      def ensure_locked!
        @accounts.each do |account|
          unless lock?(account)
            fail LockNotHeld, "No lock held for account: #{account.identifier}, scope #{account.scope}"
          end
        end
      end

      def balance_for(account)
        ensure_locked!

        locks[account]
      end

    private

      def locks
        @@locks[Thread.current.object_id]
      end

      def locks=(locks)
        @@locks[Thread.current.object_id] = locks
      end

      def remove_locks
        @@locks.delete(Thread.current.object_id)
      end

      # Return true if there's a lock on the given account.
      def lock?(account)
        in_a_locked_transaction? && locks.key?(account)
      end

      # Raise an exception unless we're outside any transactions.
      def ensure_outermost_transaction!
        minimum_transaction_level = Locking.configuration.running_inside_transactional_fixtures ? 1 : 0
        unless AccountBalance.connection.open_transactions <= minimum_transaction_level
          fail LockMustBeOutermostTransaction
        end
      end

      # Start a transaction, grab locks on the given accounts, then call the block
      # from within the transaction.
      #
      # If any account can't be locked (because there isn't a corresponding account
      # balance record), don't call the block, and return false.
      def lock_and_call
      end

      # Grab a lock on the account balance record for each account.
      #
      # Set locks to a hash mapping accounts to account balances.
      def grab_locks
        account_balances = @accounts.map { |account| AccountBalance.find_by_account(account, lock: true) }

        self.locks = Hash[*@accounts.zip(account_balances).flatten]
      end
    end

    # Raised when lock_accounts is called inside an existing transaction.
    class LockMustBeOutermostTransaction < RuntimeError
    end

    # Raised when attempting a transfer on an account that's not locked.
    class LockNotHeld < RuntimeError
    end

    # Raised if things go horribly, horribly wrong. This should never happen.
    class LockDisaster < RuntimeError
    end

    # Raised if waiting for locks times out.
    class LockWaitTimeout < RuntimeError
    end
  end
end
