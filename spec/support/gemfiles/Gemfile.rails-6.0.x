source 'https://rubygems.org'

gemspec path: '../../../'

gem 'activerecord', '~> 6.0.0'

# Rails imposed mysql2 version contraints
# https://github.com/rails/rails/blob/6-0-stable/activerecord/lib/active_record/connection_adapters/mysql2_adapter.rb#L6
gem 'mysql2', '>= 0.4.4'
