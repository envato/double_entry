# Generally used for performance tests, eg:
# expect(time_seconds).to be_faster_than(:local => 1, :ci => 1.4) # typically CI is about 1.4 times slower than local
#
# Works well with performance helpers, eg:
# require 'performance_helper'
# ...
# it 'finishes in a reasonable amount of time' do
#   start_profiling
#   do_stuff
#   result = stop_profiling('profile_name')
#   expect(total_time(result)).to be_faster_than(:local => 1, :ci => 1.4) # typically CI is about 1.4 times slower than local
# end

RSpec::Matchers.define :be_faster_than do |seconds_in_environments|
  match do |actual|
    if ENV.fetch('CI', false)
      @expected = seconds_in_environments[:ci]
    else
      @expected = seconds_in_environments[:local]
    end
    actual < @expected
  end

  failure_message do |actual|
    "expected time taken to be faster than #{@expected} seconds but was #{actual} seconds"
  end
end
