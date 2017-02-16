# encoding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'double_entry/version'

Gem::Specification.new do |gem|
  gem.name                  = 'double_entry'
  gem.version               = DoubleEntry::VERSION
  gem.authors               = ['Anthony Sellitti', 'Keith Pitt', 'Martin Jagusch', 'Martin Spickermann', 'Mark Turnley', 'Orien Madgwick', 'Pete Yandall', 'Stephanie Staub', 'Giancarlo Salamanca']
  gem.email                 = ['anthony.sellitti@envato.com', 'me@keithpitt.com', '_@mj.io', 'spickemann@gmail.com', 'mark@envato.com', '_@orien.io', 'pete@envato.com', 'staub.steph@gmail.com', 'giancarlo@salamanca.net.au']
  gem.summary               = 'Tools to build your double entry financial ledger'
  gem.homepage              = 'https://github.com/envato/double_entry'

  gem.files                 = `git ls-files`.split($/)
  gem.executables           = gem.files.grep(%r{bin/}).map { |f| File.basename(f) }
  gem.test_files            = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths         = ['lib']
  gem.required_ruby_version = '>= 2.1.0'

  gem.post_install_message = <<-'POSTINSTALLMESSAGE'
Please note the following changes in DoubleEntry:
 - New table `double_entry_line_metadata` has been introduced and is *required* for
   aggregate reporting filtering to work. Existing applications must manually manage
   this change via a migration similar to the following:

    class CreateDoubleEntryLineMetadata < ActiveRecord::Migration
      def self.up
        create_table "#{DoubleEntry.table_name_prefix}line_metadata", :force => true do |t|
          t.integer    "line_id",               :null => false
          t.string     "key",     :limit => 48, :null => false
          t.string     "value",   :limit => 64, :null => false
          t.timestamps                          :null => false
        end

        add_index "#{DoubleEntry.table_name_prefix}line_metadata",
                  ["line_id", "key", "value"],
                  :name => "lines_meta_line_id_key_value_idx"
      end

      def self.down
        drop_table "#{DoubleEntry.table_name_prefix}line_metadata"
      end
    end

  Please ensure that you update your database accordingly.
POSTINSTALLMESSAGE

  gem.add_dependency 'money',                 '>= 6.0.0'
  gem.add_dependency 'activerecord',          '>= 3.2.0'
  gem.add_dependency 'activesupport',         '>= 3.2.0'
  gem.add_dependency 'railties',              '>= 3.2.0'

  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'mysql2',    '~> 0.3.20'
  gem.add_development_dependency 'pg'
  gem.add_development_dependency 'sqlite3'

  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'rspec-its'
  gem.add_development_dependency 'rspec-instafail'
  gem.add_development_dependency 'database_cleaner'
  gem.add_development_dependency 'generator_spec'
  gem.add_development_dependency 'machinist'
  gem.add_development_dependency 'timecop'
  gem.add_development_dependency 'test-unit'

  gem.add_development_dependency 'pry'
  gem.add_development_dependency 'pry-doc'
  gem.add_development_dependency 'pry-byebug'         if RUBY_VERSION >= '2.0.0'
  gem.add_development_dependency 'pry-stack_explorer'
  gem.add_development_dependency 'awesome_print'
  gem.add_development_dependency 'ruby-prof'
end
