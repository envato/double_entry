require 'active_record'
require 'database_cleaner'
require 'erb'
require 'yaml'

FileUtils.mkdir_p 'tmp'

db_engine = ENV['DB'] || 'mysql'
database_config_file = File.join(__dir__, 'database.yml')

raise <<-MSG.strip_heredoc unless File.exist?(database_config_file)
  Please configure your spec/support/database.yml file.
  See spec/support/database.example.yml'
MSG

ActiveRecord::Base.belongs_to_required_by_default = true if ActiveRecord.version.version >= '5'
database_config_raw = File.read(database_config_file)
database_config_yaml = ERB.new(database_config_raw).result
database_config = YAML.load(database_config_yaml)
ActiveRecord::Base.establish_connection(database_config[db_engine])

RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner.strategy = :truncation
  end

  config.before(:example) do
    DatabaseCleaner.clean
  end
end
