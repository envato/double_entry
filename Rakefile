require "rspec/core/rake_task"
require "bundler/gem_tasks"

RSpec::Core::RakeTask.new(:spec) do |t|
  t.verbose = false
end

task :default do
  %w(mysql postgres sqlite).each do |db|
    puts "Running tests with `DB=#{db}`"
    ENV['DB'] = db
    Rake::Task["spec"].execute
  end
end
