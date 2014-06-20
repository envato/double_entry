# encoding: utf-8
module DoubleEntry
  class BalanceTransferrer

    def initialize(transfers)
      @transfers = transfers
    end

    def transfer(amount, options = {})
      raise TransferIsNegative if amount < Money.new(0)
      from = options[:from]
      to = options[:to]
      code = options[:code]
      meta = options[:meta]
      detail = options[:detail]

      transfer = transfers.find(from, to, code)
      if transfer
        transfer.process!(amount, from, to, code, meta, detail)
      else
        raise TransferNotAllowed.new([from.identifier, to.identifier, code].inspect)
      end
    end

  private

    attr_reader :transfers

  end
end
