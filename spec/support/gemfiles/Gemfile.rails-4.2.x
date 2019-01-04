source 'https://rubygems.org'

gemspec :path => '../../../'

gem 'activerecord', '~> 4.2.0'

# Rails imposed mysql2 version contraints
# https://github.com/rails/rails/blob/4-2-stable/activerecord/lib/active_record/connection_adapters/mysql2_adapter.rb#L3
gem 'mysql2', '>= 0.3.13', '< 0.5'
