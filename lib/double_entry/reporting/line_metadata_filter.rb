# encoding: utf-8
module DoubleEntry
  module Reporting
    class LineMetadataFilter

      def self.filter(collection:, metadata:)
        table_alias_index = 0

        metadata.reduce(collection) do |filtered_collection, (key, value)|
          table_alias = "m#{table_alias_index}"
          table_alias_index += 1

          filtered_collection.
            joins("INNER JOIN #{line_metadata_table} as #{table_alias} ON #{table_alias}.line_id = #{lines_table}.id").
            where("#{table_alias}.key = ? AND #{table_alias}.value = ?", key, value)
        end
      end

    private

      def self.line_metadata_table
        DoubleEntry::LineMetadata.table_name
      end
      private_class_method :line_metadata_table

      def self.lines_table
        DoubleEntry::Line.table_name
      end
      private_class_method :lines_table

    end
  end
end
