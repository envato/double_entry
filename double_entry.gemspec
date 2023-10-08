
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'double_entry/version'

Gem::Specification.new do |gem|
  gem.name                  = 'double_entry'
  gem.version               = DoubleEntry::VERSION
  gem.authors               = ['Envato']
  gem.email                 = ['rubygems@envato.com']
  gem.summary               = 'Tools to build your double entry financial ledger'
  gem.homepage              = 'https://github.com/envato/double_entry'
  gem.license               = 'MIT'

  gem.metadata = {
    'bug_tracker_uri'   => 'https://github.com/envato/double_entry/issues',
    'changelog_uri'     => "https://github.com/envato/double_entry/blob/v#{gem.version}/CHANGELOG.md",
    'documentation_uri' => "https://www.rubydoc.info/gems/double_entry/#{gem.version}",
    'source_code_uri'   => "https://github.com/envato/double_entry/tree/v#{gem.version}",
  }

  gem.files                 = `git ls-files -z`.split("\x0").select do |f|
    f.match(%r{^(?:double_entry.gemspec|README|LICENSE|CHANGELOG|lib/)})
  end
  gem.require_paths         = ['lib']
  gem.required_ruby_version = '>= 3'

  gem.add_dependency 'activerecord',          '>= 6.1.0'
  gem.add_dependency 'activesupport',         '>= 6.1.0'
  gem.add_dependency 'money',                 '>= 6.0.0'
  gem.add_dependency 'railties',              '>= 6.1.0'

  gem.add_development_dependency 'mysql2'
  gem.add_development_dependency 'pg'
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'sqlite3'

  gem.add_development_dependency 'database_cleaner'
  gem.add_development_dependency 'factory_bot'
  gem.add_development_dependency 'generator_spec'
  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'rspec-its'
  gem.add_development_dependency 'ruby-prof'
  gem.add_development_dependency 'timecop'
end
