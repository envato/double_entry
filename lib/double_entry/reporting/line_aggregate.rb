# encoding: utf-8
module DoubleEntry
 module Reporting
  class LineAggregate < ActiveRecord::Base
    extend EncapsulateAsMoneyWithCurrency

    def self.aggregate(function, account, code, range, named_scopes)
      collection = aggregate_collection(named_scopes)
      collection = collection.where(:account => account)
      collection = collection.where(:created_at => range.start..range.finish)
      collection = collection.where(:code => code) if code
      collection.send(function, :amount)
    end

    # a lot of the trickier reports will use filters defined
    # in named_scopes to bring in data from other tables.
    def self.aggregate_collection(named_scopes)
      if named_scopes
        collection = DoubleEntry::Line
        named_scopes.each do |named_scope|
          if named_scope.is_a?(Hash)
            method_name = named_scope.keys[0]
            collection = collection.send(method_name, named_scope[method_name])
          else
            collection = collection.send(named_scope)
          end
        end
        collection
      else
        DoubleEntry::Line
      end
    end

    def key
      "#{year}:#{month}:#{week}:#{day}:#{hour}"
    end
  end
 end
end
