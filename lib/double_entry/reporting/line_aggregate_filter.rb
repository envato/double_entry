# encoding: utf-8
module DoubleEntry
  module Reporting
    class LineAggregateFilter

      def initialize(account, code, range, filter_criteria)
        @account         = account
        @code            = code
        @range           = range
        @filter_criteria = filter_criteria
      end

      def filter
        @collection ||= apply_filters
      end

    private

      attr_reader :account, :code, :range, :filter_criteria

      def apply_filters
        collection = filter_collection.
                     where(:account => account).
                     where(:created_at => range.start..range.finish)
        collection = collection.where(:code => code) if code

        collection
      end

      # a lot of the trickier reports will use filters defined
      # in filter_criteria to bring in data from other tables.
      # For example:
      #
      #   filter_criteria = [
      #     # an example of calling a named scope called with arguments
      #     {
      #       :scope => {
      #         :name => :ten_dollar_purchases_by_category,
      #         :arguments => [:cat_videos, :cat_pictures]
      #       }
      #     },
      #     # an example of calling a named scope with no arguments
      #     {
      #       :scope => {
      #         :name => :ten_dollar_purchases
      #       }
      #     },
      #     # an example of providing metadata criteria to filter on
      #     {
      #       :metadata => {
      #         :meme => :business_cat,
      #         :meme => :grumpy_cat
      #       }
      #     }
      #   ]
      def filter_collection
        if filter_criteria
          collection = DoubleEntry::Line
          filter_criteria.each do |named_scope|
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
    end
  end
end
