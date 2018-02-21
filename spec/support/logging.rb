require 'active_record'
require 'active_support/logger'

RSpec.configure do |config|
  config.before(:suite) do
    log_file = File.expand_path('../../../log/test.log', __FILE__)

    FileUtils.mkdir_p(File.dirname(log_file))
    FileUtils.rm(log_file, force: true)
    ActiveRecord::Base.logger = ActiveSupport::Logger.new(log_file)
  end
end
