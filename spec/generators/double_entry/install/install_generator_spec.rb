require 'action_controller'
require 'generator_spec/test_case'
require 'generators/double_entry/install/install_generator'

RSpec.describe DoubleEntry::Generators::InstallGenerator do
  include GeneratorSpec::TestCase

  # Needed until a new release of generator_spec gem with https://github.com/stevehodgkiss/generator_spec/pull/47
  module GeneratorSpec::Matcher
    class Migration
      def does_not_contain(text)
        @does_not_contain << text
      end

      def check_contents(file)
        contents = ::File.read(file)

        @contents.each do |string|
          unless contents.include?(string)
            throw :failure, [file, string, contents]
          end
        end

        @does_not_contain.each do |string|
          if contents.include?(string)
            throw :failure, [:not, file, string, contents]
          end
        end
      end
    end

    class Root
      def failure_message
        if @failure.is_a?(Array) && @failure[0] == :not
          if @failure.length > 2
            "Structure should have #{@failure[1]} without #{@failure[2]}. It had:\n#{@failure[3]}"
          else
            "Structure should not have had #{@failure[1]}, but it did"
          end
        elsif @failure.is_a?(Array)
          "Structure should have #{@failure[0]} with #{@failure[1]}. It had:\n#{@failure[2]}"
        else
          "Structure should have #{@failure}, but it didn't"
        end
      end
    end
  end

  destination File.expand_path('../../../../../tmp/generators', __FILE__)

  before do
    prepare_destination
  end

  def expect_migration_to_have_structure(&block)
    expect(destination_root).to have_structure {
      directory 'db' do
        directory 'migrate' do
          migration 'create_double_entry_tables' do
            @does_not_contain = []
            contains 'class CreateDoubleEntryTables'
            contains 'create_table "double_entry_account_balances"'
            contains 'create_table "double_entry_lines"'
            contains 'create_table "double_entry_line_checks"'
            instance_eval(&block)
          end
        end
      end
    }
  end

  RSpec.shared_examples 'with_json_metadata' do
    it 'generates the expected migrations' do
      expect_migration_to_have_structure do
        contains 't.json "metadata"'
        does_not_contain 'create_table "double_entry_line_metadata"'
      end
    end

    it 'generates the expected initializer' do
      expect(destination_root).to have_structure {
        directory 'config' do
          directory 'initializers' do
            file 'double_entry.rb' do
              contains 'config.json_metadata = true'
            end
          end
        end
      }
    end
  end

  RSpec.shared_examples 'without_json_metadata' do
    it 'generates the expected migrations' do
      expect_migration_to_have_structure do
        contains 'create_table "double_entry_line_metadata"'
        contains 'add_index "double_entry_line_metadata"'
        does_not_contain 't.json "metadata"'
      end
    end

    it 'generates the expected initializer' do
      expect(destination_root).to have_structure {
        directory 'config' do
          directory 'initializers' do
            file 'double_entry.rb' do
              contains 'config.json_metadata = false'
            end
          end
        end
      }
    end
  end

  context 'without arguments' do
    before { run_generator }

    examples = ActiveRecord.version.version < '5' ? 'without_json_metadata' : 'with_json_metadata'
    include_examples examples
  end

  context 'with --json-metadata' do
    before { run_generator %w(--json-metadata) }

    examples = ActiveRecord.version.version < '5' ? 'without_json_metadata' : 'with_json_metadata'
    include_examples examples
  end

  context 'with --no-json-metadata' do
    before { run_generator %w(--no-json-metadata) }

    include_examples 'without_json_metadata'
  end
end
