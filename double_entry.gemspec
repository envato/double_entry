# encoding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'double_entry/version'

Gem::Specification.new do |gem|
  gem.name          = "double_entry"
  gem.version       = DoubleEntry::VERSION
  gem.authors       = ["Anthony Sellitti", "Orien Madgwick", "Keith Pitt", "Martin Jagusch", "Martin Spickermann", "Mark Turnley", "Pete Yandall"]
  gem.email         = ["anthony.sellitti@envato.com", "_@orien.io", "me@keithpitt.com", "_@mj.io", "spickemann@gmail.com", "mark@envato.com", "pete@envato.com"]
  # gem.description   = %q{}
  gem.summary       = "Tools to build your double entry financial ledger"
  gem.homepage      = "https://github.com/envato/double_entry"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency "money", ">= 5.1.0"
  gem.add_dependency "activerecord", ">= 3.2.9"
  gem.add_dependency "encapsulate_as_money"

  gem.add_development_dependency "pg"
  gem.add_development_dependency "mysql2"
  gem.add_development_dependency "rspec"
  gem.add_development_dependency "rspec-its"
  gem.add_development_dependency "timecop"
  gem.add_development_dependency "database_cleaner"
  gem.add_development_dependency "machinist"
  gem.add_development_dependency "rake"
  gem.add_development_dependency "jazz_hands"
  gem.add_development_dependency "generator_spec"
end
