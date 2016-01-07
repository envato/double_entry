# encoding: utf-8
module DoubleEntry
  module Reporting
    class LineAggregateFilter
      def initialize(account:, partner_account:, code:, range:, filter_criteria:)
        @account         = account
        @partner_account = partner_account
        @code            = code
        @range           = range
        @filter_criteria = filter_criteria || []
      end

      def filter
        @collection ||= apply_filters
      end

    private

      def apply_filters
        collection = apply_filter_criteria.
                     where(:account => @account).
                     where(:created_at => @range.start..@range.finish)
        collection = collection.where(:code => @code) if @code
        collection = collection.where(:partner_account => @partner_account) if @partner_account

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
        @filter_criteria.reduce(DoubleEntry::Line) do |collection, filter|
          if filter[:scope].present?
            filter_by_scope(collection, filter[:scope])
          elsif filter[:metadata].present?
            filter_by_metadata(collection, filter[:metadata])
          else
            collection
          end
        end
      end

      def filter_by_scope(collection, scope)
        collection.public_send(scope[:name], *scope[:arguments])
      end

      def filter_by_metadata(collection, metadata)
        metadata.reduce(collection.joins(:metadata)) do |filtered_collection, (key, value)|
          filtered_collection.where(metadata_table => { :key => key, :value => value })
        end
      end

      def metadata_table
        DoubleEntry::LineMetadata.table_name.to_sym
      end
    end
  end
end
