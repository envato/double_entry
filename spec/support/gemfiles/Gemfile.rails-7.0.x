source 'https://rubygems.org'

gemspec path: '../../../'

gem 'activerecord', '~> 7.0.0'

# Rails imposed mysql2 version contraints
# https://github.com/rails/rails/blob/7-0-stable/activerecord/lib/active_record/connection_adapters/mysql2_adapter.rb#L6
gem 'mysql2', '~> 0.5'
