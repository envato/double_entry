# encoding: utf-8
RSpec.configure do |config|
  config.before do
    DoubleEntry::Reporting.instance_variable_set(:@configuration, nil)
  end
end
