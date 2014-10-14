# encoding: utf-8
module DoubleEntry
  class Transfer

    # @api private
    def self.transfer(defined_transfers, amount, options = {})
      raise TransferIsNegative if amount < Money.empty
      from, to, code, detail = options[:from], options[:to], options[:code],  options[:detail]
      defined_transfers.
        find!(from, to, code).
        process(amount, from, to, code, detail)
    end

    # @api private
    class Set < Array
      def define(attributes)
        self << Transfer.new(attributes)
      end

      def find(from, to, code)
        _find(from.identifier, to.identifier, code)
      end

      def find!(from, to, code)
        transfer = find(from, to, code)
        raise TransferNotAllowed.new([from.identifier, to.identifier, code].inspect) unless transfer
        return transfer
      end

      def <<(transfer)
        if _find(transfer.from, transfer.to, transfer.code)
          raise DuplicateTransfer.new
        else
          super(transfer)
        end
      end

    private

      def _find(from, to, code)
        detect do |transfer|
          transfer.from == from and transfer.to == to and transfer.code == code
        end
      end
    end

    attr_accessor :code, :from, :to, :description

    def initialize(attributes)
      attributes.each { |name, value| send("#{name}=", value) }
    end

    def process(amount, from, to, code, detail)
      if from.scope_identity == to.scope_identity and from.identifier == to.identifier
        raise TransferNotAllowed.new("from and to are identical")
      end
      if to.currency != from.currency
        raise MismatchedCurrencies.new("Missmatched currency (#{to.currency} <> #{from.currency})")
      end
      Locking.lock_accounts(from, to) do
        credit, debit = Line.new, Line.new

        credit_balance = Locking.balance_for_locked_account(from)
        debit_balance  = Locking.balance_for_locked_account(to)

        credit_balance.update_attribute :balance, credit_balance.balance - amount
        debit_balance.update_attribute  :balance, debit_balance.balance  + amount

        credit.amount,  debit.amount  = -amount, amount
        credit.account, debit.account = from, to
        credit.code,    debit.code    = code, code
        credit.detail,  debit.detail  = detail, detail
        credit.balance, debit.balance = credit_balance.balance, debit_balance.balance

        credit.partner_account, debit.partner_account = to, from

        credit.save!
        debit.partner_id = credit.id
        debit.save!
        credit.update_attribute :partner_id, debit.id
      end
    end

  end
end
