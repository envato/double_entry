source 'https://rubygems.org'

gemspec :path => '../../../'

gem 'activerecord', '~> 5.1.0'

# Rails imposed mysql2 version contraints
# https://github.com/rails/rails/blob/5-1-stable/activerecord/lib/active_record/connection_adapters/mysql2_adapter.rb#L4
gem 'mysql2', '>= 0.3.18', '< 0.6.0'
