require 'active_record'
require 'database_cleaner'

FileUtils.mkdir_p 'tmp'

db_engine = ENV['DB'] || 'mysql'
database_config_file = File.expand_path('../database.yml', __FILE__)

raise <<-MSG.strip_heredoc unless File.exist?(database_config_file)
  Please configure your spec/support/database.yml file.
  See spec/support/database.example.yml'
MSG

ActiveRecord::Base.establish_connection(YAML.load_file(database_config_file)[db_engine])

RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner.strategy = :truncation
  end

  config.before(:example) do
    DatabaseCleaner.clean
  end
end
