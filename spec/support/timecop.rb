require 'timecop'

RSpec.configure do |config|
  config.after(:example) do
    Timecop.return
  end
end
