source 'https://rubygems.org'

gemspec path: '../../../'

gem 'activerecord', '~> 6.1.0'

# Rails imposed database gem constraints
gem 'mysql2', '~> 0.5' # https://github.com/rails/rails/blob/6-1-stable/activerecord/lib/active_record/connection_adapters/mysql2_adapter.rb#L6
gem 'pg', '~> 1.1' # https://github.com/rails/rails/blob/6-1-stable/activerecord/lib/active_record/connection_adapters/postgresql_adapter.rb#L3
gem 'sqlite3', '~> 1.4' # https://github.com/rails/rails/blob/6-1-stable/activerecord/lib/active_record/connection_adapters/sqlite3_adapter.rb#L14
