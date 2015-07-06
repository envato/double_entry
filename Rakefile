require 'rspec/core/rake_task'
require 'bundler/gem_tasks'
require 'rubocop/rake_task'

RSpec::Core::RakeTask.new(:spec) do |t|
  t.verbose = false
  t.ruby_opts = '-w'
end

RuboCop::RakeTask.new(:rubocop) do |t|
  t.fail_on_error = true
end

task :default do
  %w(mysql postgres sqlite).each do |db|
    puts "Running tests with `DB=#{db}`"
    ENV['DB'] = db
    Rake::Task['spec'].execute
  end
  Rake::Task['rubocop'].execute
end
