module DoubleEntry
  class LineMetadata < ActiveRecord::Base
    class SymbolWrapper
      def self.load(string)
        return unless string
        string.to_sym
      end

      def self.dump(symbol)
        return unless symbol
        symbol.to_s
      end
    end

    belongs_to :line
    serialize :key, coder: DoubleEntry::LineMetadata::SymbolWrapper
  end
end
