source 'https://rubygems.org'

gemspec :path => '../../../'

gem 'rails', '~> 3.2.0'

# Rails imposed mysql2 version contraints
# https://github.com/rails/rails/blob/3-2-stable/activerecord/lib/active_record/connection_adapters/mysql2_adapter.rb#L3
gem 'mysql2', '~> 0.3.10'

gem 'i18n', '0.6.11'
