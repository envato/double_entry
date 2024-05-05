# encoding: utf-8
module DoubleEntry
  module Money
    class << self
      attr_writer :adapter

      def adapter
        @adapter ||= DoubleEntry.config.money_adapter
      end

      delegate(:new, to: :adapter)
      delegate_missing_to(:adapter)
    end
  end
end
