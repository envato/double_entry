require 'rails/generators'
require 'rails/generators/migration'
require 'rails/generators/active_record'

module DoubleEntry
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration
      extend ActiveRecord::Generators::Migration

      source_root File.expand_path('../templates', __FILE__)

      def copy_migrations
        migration_template "migration.rb", "db/migrate/create_double_entry_tables.rb"
      end

    end
  end
end
