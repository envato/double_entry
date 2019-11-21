require 'rails/generators'
require 'rails/generators/migration'
require 'rails/generators/active_record'

module DoubleEntry
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration

      class_option :json_metadata, type: :boolean, default: true

      source_root File.expand_path('../templates', __FILE__)

      def self.next_migration_number(path)
        ActiveRecord::Generators::Base.next_migration_number(path)
      end

      def copy_migrations
        migration_template 'migration.rb', 'db/migrate/create_double_entry_tables.rb', migration_version: migration_version
      end

      def create_initializer
        template 'initializer.rb', 'config/initializers/double_entry.rb'
      end

      def json_metadata
        # MySQL JSON support added to AR 5.0
        if ActiveRecord.version.version < '5'
          false
        else
          options[:json_metadata]
        end
      end

      def migration_version
        if ActiveRecord.version.version > '5'
          "[#{ActiveRecord::VERSION::MAJOR}.#{ActiveRecord::VERSION::MINOR}]"
        end
      end
    end
  end
end
