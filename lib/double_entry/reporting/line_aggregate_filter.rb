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
        collection = apply_filter_criteria.
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
      #     # an example of providing a single metadatum criteria to filter on
      #     {
      #       :metadata => {
      #         :meme => :business_cat
      #       }
      #     }
      #   ]
      def apply_filter_criteria
        collection = DoubleEntry::Line

        if filter_criteria.present?
          filter_criteria.each do |filter|
            collection = filter_by_scope(collection, filter[:scope]) if filter[:scope].present?
            collection = filter_by_metadata(collection, filter[:metadata])  if filter[:metadata].present?
          end
        end

        collection
      end

      def filter_by_scope(collection, scope)
        collection.public_send(scope[:name], *scope[:arguments])
      end

      def filter_by_metadata(collection, metadata)
        collection = collection.joins(:metadata)

        metadata.each do |key, value|
          collection = collection.where(metadata_table => { :key => key, :value => value })
        end

        collection
      end

      def metadata_table
        DoubleEntry::LineMetadata.table_name.to_sym
      end
    end
  end
end
