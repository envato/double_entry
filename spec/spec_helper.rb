# encoding: utf-8
require 'bundler/setup'
require 'active_record'
require 'active_support'

ENV['DB'] ||= 'mysql'
ActiveRecord::Base.establish_connection YAML.load_file(File.expand_path("../support/database.yml", __FILE__))[ENV['DB']]

FileUtils.mkdir_p 'log'
FileUtils.rm 'log/test.log', :force => true
ActiveRecord::Base.logger = ActiveSupport::Logger.new('log/test.log')
I18n.config.enforce_available_locales = false

require 'double_entry'
require 'rspec'
require 'rspec/its'
require 'database_cleaner'
require 'machinist/active_record'
require 'timecop'

Dir[File.expand_path("../support/**/*.rb", __FILE__)].each { |f| require f }

RSpec.configure do |config|
  config.include DoubleEntrySpecHelper

  config.before(:suite) do
    DatabaseCleaner.strategy = :deletion
    DatabaseCleaner.clean_with(:deletion)
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    Timecop.return
    DatabaseCleaner.clean
  end
end
