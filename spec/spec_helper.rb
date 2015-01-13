# encoding: utf-8
require 'bundler/setup'
require 'active_record'
require 'active_support'

db_engine = ENV['DB'] || 'mysql'

FileUtils.mkdir_p 'tmp'
FileUtils.mkdir_p 'log'
FileUtils.rm 'log/test.log', :force => true

database_config_file = File.expand_path("../support/database.yml", __FILE__)
if File.exists?(database_config_file)
  ActiveRecord::Base.establish_connection YAML.load_file(database_config_file)[db_engine]
else
  puts "Please configure your spec/support/database.yml file."
  puts "See spec/support/database.example.yml"
  exit 1
end

# Buffered Logger was deprecated in ActiveSupport 4.0.0 and was removed in 4.1.0
# Logger was added in ActiveSupport 4.0.0
if defined? ActiveSupport::Logger
  ActiveRecord::Base.logger = ActiveSupport::Logger.new('log/test.log')
else
  ActiveRecord::Base.logger = ActiveSupport::BufferedLogger.new('log/test.log')
end

I18n.config.enforce_available_locales = false

require 'double_entry'
require 'rspec'
require 'rspec/its'
require 'database_cleaner'
require 'machinist/active_record'
require 'timecop'

Dir[File.expand_path("../support/**/*.rb", __FILE__)].each { |f| require f }

RSpec.configure do |config|
  # rspec-expectations config goes here. You can use an alternate
  # assertion/expectation library such as wrong or the stdlib/minitest
  # assertions if you prefer.
  config.expect_with :rspec do |expectations|
    # This option will default to `true` in RSpec 4. It makes the `description`
    # and `failure_message` of custom matchers include text for helper methods
    # defined using `chain`, e.g.:
    # be_bigger_than(2).and_smaller_than(4).description
    #   # => "be bigger than 2 and smaller than 4"
    # ...rather than:
    #   # => "be bigger than 2"
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  # rspec-mocks config goes here. You can use an alternate test double
  # library (such as bogus or mocha) by changing the `mock_with` option here.
  config.mock_with :rspec do |mocks|
    # Prevents you from mocking or stubbing a method that does not exist on
    # a real object. This is generally recommended, and will default to
    # `true` in RSpec 4.
    mocks.verify_partial_doubles = true
  end

  # These two settings work together to allow you to limit a spec run
  # to individual examples or groups you care about by tagging them with
  # `:focus` metadata. When nothing is tagged with `:focus`, all examples
  # get run.
  config.filter_run :focus
  config.run_all_when_everything_filtered = true

  # Limits the available syntax to the non-monkey patched syntax that is recommended.
  # For more details, see:
  #   - http://myronmars.to/n/dev-blog/2012/06/rspecs-new-expectation-syntax
  #   - http://teaisaweso.me/blog/2013/05/27/rspecs-new-message-expectation-syntax/
  #   - http://myronmars.to/n/dev-blog/2014/05/notable-changes-in-rspec-3#new__config_option_to_disable_rspeccore_monkey_patching
  config.disable_monkey_patching!

  # Many RSpec users commonly either run the entire suite or an individual
  # file, and it's useful to allow more verbose output when running an
  # individual spec file.
  if config.files_to_run.one?
    # Use the documentation formatter for detailed output,
    # unless a formatter has already been configured
    # (e.g. via a command-line flag).
    config.default_formatter = 'doc'
  else
    config.default_formatter = 'RSpec::Instafail'
  end

  # Print the 5 slowest examples and example groups at the
  # end of the spec run, to help surface which specs are running
  # particularly slow.
  config.profile_examples = 5


  config.include DoubleEntrySpecHelper

  config.before(:suite) do
    DatabaseCleaner.strategy = :truncation
  end

  config.before do
    DatabaseCleaner.clean
  end

  config.after do
    Timecop.return
  end
end
