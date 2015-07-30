# encoding: utf-8
module DoubleEntry
  module Reporting
    class LineAggregate < ActiveRecord::Base
      def self.aggregate(function, account, code, range, named_scopes)
        collection_filter = LineAggregateFilter.new(account, code, range, named_scopes)
        collection = collection_filter.filter
        collection.send(function, :amount)
      end

      def key
        "#{year}:#{month}:#{week}:#{day}:#{hour}"
      end
    end
  end
end
