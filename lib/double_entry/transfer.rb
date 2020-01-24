# encoding: utf-8
require 'forwardable'

module DoubleEntry
  class Transfer
    class << self
      attr_accessor :code_max_length
      attr_writer :transfers

      # @api private
      def transfers
        @transfers ||= Set.new
      end

      # @api private
      def transfer(amount, options = {})
        fail TransferIsNegative if amount.negative?
        from_account = options[:from]
        to_account = options[:to]
        code = options[:code]
        transfers.find!(from_account, to_account, code).process(amount, options)
      end
    end

    # @api private
    class Set
      extend Forwardable
      delegate [:each, :map] => :all

      def define(attributes)
        Transfer.new(attributes).tap do |transfer|
          key = [transfer.from, transfer.to, transfer.code]
          if _find(*key)
            fail DuplicateTransfer
          else
            backing_collection[key] = transfer
          end
        end
      end

      def find(from_account, to_account, code)
        _find(from_account.identifier, to_account.identifier, code)
      end

      def find!(from_account, to_account, code)
        find(from_account, to_account, code).tap do |transfer|
          fail TransferNotAllowed, [from_account.identifier, to_account.identifier, code].inspect unless transfer
        end
      end

      def all
        backing_collection.values
      end

    private

      def backing_collection
        @backing_collection ||= Hash.new
      end

      def _find(from, to, code)
        backing_collection[[from, to, code]]
      end
    end

    attr_reader :code, :from, :to

    def initialize(attributes)
      @code = attributes[:code]
      @from = attributes[:from]
      @to = attributes[:to]
      if Transfer.code_max_length && code.length > Transfer.code_max_length
        fail TransferCodeTooLongError,
             "transfer code '#{code}' is too long. Please limit it to #{Transfer.code_max_length} characters."
      end
    end

    def process(amount, options)
      from_account = options[:from]
      to_account = options[:to]
      code = options[:code]
      detail = options[:detail]
      metadata = options[:metadata]
      if from_account.scope_identity == to_account.scope_identity && from_account.identifier == to_account.identifier
        fail TransferNotAllowed, 'from account and to account are identical'
      end
      if to_account.currency != from_account.currency
        fail MismatchedCurrencies, "Mismatched currency (#{to_account.currency} <> #{from_account.currency})"
      end
      Locking.lock_accounts(from_account, to_account) do
        credit, debit = create_lines(amount, code, detail, from_account, to_account, metadata)
        create_line_metadata(credit, debit, metadata) if metadata && !DoubleEntry.config.json_metadata
      end
    end

    def create_lines(amount, code, detail, from_account, to_account, metadata)
      credit, debit = Line.new, Line.new

      credit_balance = Locking.balance_for_locked_account(from_account)
      debit_balance  = Locking.balance_for_locked_account(to_account)

      credit_balance.update_attribute :balance, credit_balance.balance - amount
      debit_balance.update_attribute :balance, debit_balance.balance + amount

      credit.amount, debit.amount   = -amount, amount
      credit.account, debit.account = from_account, to_account
      credit.code, debit.code       = code, code
      credit.detail, debit.detail   = detail, detail
      credit.balance, debit.balance = credit_balance.balance, debit_balance.balance
      credit.metadata, debit.metadata = metadata, metadata if DoubleEntry.config.json_metadata

      credit.partner_account, debit.partner_account = to_account, from_account

      credit.save!
      debit.partner_id = credit.id
      debit.save!
      credit.update_attribute :partner_id, debit.id
      [credit, debit]
    end

    def create_line_metadata(credit, debit, metadata)
      metadata.each_pair do |key, value|
        Array(value).each do |each_value|
          LineMetadata.create!(:line => credit, :key => key, :value => each_value)
          LineMetadata.create!(:line => debit, :key => key, :value => each_value)
        end
      end
    end
  end
end
