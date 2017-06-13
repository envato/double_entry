require 'action_controller'
require 'generator_spec/test_case'
require 'generators/double_entry/install/install_generator'

RSpec.describe DoubleEntry::Generators::InstallGenerator do
  include GeneratorSpec::TestCase

  destination File.expand_path('../../../../../tmp', __FILE__)

  before do
    prepare_destination
    run_generator
  end

  specify do
    expect(destination_root).to have_structure {
      directory 'db' do
        directory 'migrate' do
          migration 'create_double_entry_tables' do
            contains 'class CreateDoubleEntryTable'
            contains 'create_table "double_entry_account_balances"'
            contains 'create_table "double_entry_lines"'
            contains 'create_table "double_entry_line_aggregates"'
            contains 'create_table "double_entry_line_checks"'
          end
        end
      end
    }
  end
end
