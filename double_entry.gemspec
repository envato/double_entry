# encoding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'double_entry/version'

Gem::Specification.new do |gem|
  gem.name          = 'double_entry'
  gem.version       = DoubleEntry::VERSION
  gem.authors       = ['Anthony Sellitti', 'Keith Pitt', 'Martin Jagusch', 'Martin Spickermann', 'Mark Turnley', 'Orien Madgwick', 'Pete Yandall', 'Stephanie Staub']
  gem.email         = ['anthony.sellitti@envato.com', 'me@keithpitt.com', '_@mj.io', 'spickemann@gmail.com', 'mark@envato.com', '_@orien.io', 'pete@envato.com', 'staub.steph@gmail.com']
  # gem.description   = %q{}
  gem.summary       = 'Tools to build your double entry financial ledger'
  gem.homepage      = 'https://github.com/envato/double_entry'

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']

  gem.add_dependency 'money',                 '>= 6.0.0'
  gem.add_dependency 'activerecord',          '>= 3.2.0'
  gem.add_dependency 'activesupport',         '>= 3.2.0'
  gem.add_dependency 'railties',              '>= 3.2.0'

  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'mysql2'
  gem.add_development_dependency 'pg'
  gem.add_development_dependency 'sqlite3'

  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'rspec-its'
  gem.add_development_dependency 'database_cleaner'
  gem.add_development_dependency 'generator_spec'
  gem.add_development_dependency 'machinist'
  gem.add_development_dependency 'timecop'
end
