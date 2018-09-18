source 'https://rubygems.org'

gemspec :path => '../../../'

gem 'rails', '~> 5.2.0'

# Rails imposed mysql2 version contraints
# https://github.com/rails/rails/blob/5-2-stable/activerecord/lib/active_record/connection_adapters/mysql2_adapter.rb#L4
gem 'mysql2', '>= 0.4.4', '< 0.6.0'
