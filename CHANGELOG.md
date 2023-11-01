# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]

[Unreleased]: https://github.com/envato/double_entry/compare/v2.0.1...HEAD

## [2.0.1] - 2023-11-01

### Fixed

- Resolve Rails 7.1 coder deprecation warning ([#219]).

[2.0.1]: https://github.com/envato/double_entry/compare/v2.0.0...v2.0.1
[#219]: https://github.com/envato/double_entry/pull/219

## [2.0.0] - 2023-10-25

### Fixed

- Ensure LineCheck and AccountFixer can work correctly with unscoped accounts ([#207]).
- Fixes for running on Ruby 3 ([#212]).

### Changed

- Return `[credit, debit]` from `DoubleEntry.transfer` ([#190]).
- Run the test suite against Rails 6.1, 7.0, 7.1, and Ruby 3.1, 3.2 ([#203], [#214], [#217]).
- Migrate CI to run on GitHub Actions ([#205])

### Removed

- Removed support for Rails < 6.1, and Ruby < 3.0 ([#215], [#217]).

### Added

- Add `credit` and `debit` scopes to the `Line` model ([#192]).

[2.0.0]: https://github.com/envato/double_entry/compare/v2.0.0.beta5...v2.0.0
[#190]: https://github.com/envato/double_entry/pull/190
[#192]: https://github.com/envato/double_entry/pull/192
[#203]: https://github.com/envato/double_entry/pull/203
[#205]: https://github.com/envato/double_entry/pull/205
[#207]: https://github.com/envato/double_entry/pull/207
[#212]: https://github.com/envato/double_entry/pull/212
[#214]: https://github.com/envato/double_entry/pull/214
[#215]: https://github.com/envato/double_entry/pull/215
[#217]: https://github.com/envato/double_entry/pull/217

## [2.0.0.beta5] - 2021-02-24

### Changed

- Use the Ruby 1.9 hash syntax ([#182]).
- Make the Line detail association optional ([#184]).
- Support Ruby 3 ([#196]).

[#182]: https://github.com/envato/double_entry/pull/182
[#184]: https://github.com/envato/double_entry/pull/184
[#196]: https://github.com/envato/double_entry/pull/196

## [2.0.0.beta4] - 2020-01-25

### Added

- Test against Rails 6.0, ([#176]).

- Support for Ruby 2.7 ([#180]).

### Changed

- Metadata stored by default in a json(b) column for new installs ([#178]).

- Remove `force: true` from migration ([#181]).

- Prevent using Ruby 2.2 via restrictions in Gemfile and Gemspec ([#175]).

[#175]: https://github.com/envato/double_entry/pull/175
[#176]: https://github.com/envato/double_entry/pull/176
[#178]: https://github.com/envato/double_entry/pull/178
[#180]: https://github.com/envato/double_entry/pull/180
[#181]: https://github.com/envato/double_entry/pull/181

## [2.0.0.beta3] - 2019-11-14

### Fixed

- Remove duplicate detail columns in `double_entry_lines` table migration, ([#173]).

[#173]: https://github.com/envato/double_entry/pull/173

## [2.0.0.beta2] - 2019-01-27

### Removed

- Extract `DoubleEntry::Reporting` module to a separate gem:
  [`double_entry-reporting`](https://github.com/envato/double_entry-reporting).

  If this module is in use in your project add the `double_entry-reporting` gem
  and checkout the
  [changelog](https://github.com/envato/double_entry-reporting/blob/master/CHANGELOG.md)
  for more updates.

  If not in use, one can delete the `double_entry_line_aggregates` table using
  the following migration:

    ```ruby
    drop_table :double_entry_line_aggregates
    ```

## [2.0.0.beta1] - 2018-12-31

### Added

- Added contributor credits to README.

- Added support for Ruby 2.3, 2.4, 2.5 and 2.6.

- Added support for Rails 5.0, 5.1 and 5.2

- Support passing an array of metadata values.

    ```ruby
    DoubleEntry.transfer(
      Money.new(20_00),
      :from     => one_account,
      :to       => another_account,
      :code     => :a_business_code_for_this_type_of_transfer,
      :metadata => { :key1 => ['value 1', 'value 2'], :key2 => 'value 3' },
    )
    ```

- Allow partner account to be specified for aggregates.

- Allow filtering aggregates by multiple metadata key/value pairs.

- Add index on the `double_entry_line_checks` table. This covers the query to
  obtain the last line check.

  Add this index to your database via a migration like:

    ```ruby
    def up
      add_index "double_entry_line_checks", ["created_at", "last_line_id"], :name => "line_checks_created_at_last_line_id_idx"
    end
    ```

- Log account balance cache errors to the database when performing the line check:
  `DoubleEntry::Validation::LineCheck::perform!`

### Changed

- Replaced Machinist with Factory Bot in test suite.

- Implement `DoubleEntry::Transfer::Set` and `DoubleEntry::Account::Set` with
  `Hash`es rather than `Array`s for performance.

- Reporting API now uses keyword arguments. Note these reporting classes are
  marked API private: their interface is not considered stable.
  - `DoubleEntry::Reporting::aggregate`
  - `DoubleEntry::Reporting::aggregate_array`
  - `DoubleEntry::Reporting::Aggregate::new`
  - `DoubleEntry::Reporting::Aggregate::formatted_amount`
  - `DoubleEntry::Reporting::AggregateArray::new`
  - `DoubleEntry::Reporting::LineAggregateFilter::new`

- Loosened database string column contstraints to the default (255 characters).
  Engineering teams can choose to apply this change, or apply their own column
  length constraints specific to their needs. ([#152])

- Removed default values for the length checks on `code`, `account` and `scope`
  ([#152]). These checks will now only be performed when configured with a value:

   ```ruby
   DoubleEntry.configure do |config|
     config.code_max_length = 47
     config.account_identifier_max_length = 31
     config.scope_identifier_max_length = 23
   end
   ```
- Use `bigint` for monetary values in the database to avoid integer overflow
  ([#154]). Apply changes via this migration:

   ```ruby
   change_column :double_entry_account_balances, :balance, :bigint, null: false

   change_column :double_entry_line_aggregates, :amount, :bigint, null: false

   change_column :double_entry_lines, :amount, :bigint, null: false
   change_column :double_entry_lines, :balance, :bigint, null: false
   ```
- On Rails version 5.1 and above, use `bigint` for foreign key values in the
  database to avoid integer overflow ([#154]). Apply changes via this
  migration:

   ```ruby
   change_column :double_entry_line_checks, :last_line_id, :bigint, null: false

   change_column :double_entry_line_metadata, :line_id, :bigint, null: false

   change_column :double_entry_lines, :partner_id, :bigint, null: true
   change_column :double_entry_lines, :detail_id, :bigint, null: true
   ```

- Line check validation no-longer performs corrections by default. The
  `DoubleEntry::Validation::LineCheck::perform!` method will only log validation
  failures in the database. To perform auto-correction pass the `fixer` option:
  `LineCheck.perform!(fixer: DoubleEntry::Validation::AccountFixer.new)`

### Removed

- Removed support for Ruby 1.9, 2.0, 2.1 and 2.2.

- Removed support for Rails 3.2, 4.0, and 4.1.

- Removed unneeded development dependencies from Gemspec.

- Removed spec and script files from gem package.

- Removed the `active_record_scope_identifier` method for configuring scoped accounts.

    ```ruby
    user_scope = accounts.active_record_scope_identifier(User)
    ```

  As a replacement, please define your own with a lambda:

    ```ruby
    user_scope = ->(user) do
      raise 'not a User' unless user.class.name == 'User'
      user.id
    end
    ```

### Fixed

- Fixed more Ruby warnings.

- Use `double_entry` namespace when publishing to
  `ActiveSupport::Notifications`.

- Fixed problem of Rails version number not being set in migration template for apps using Rails 5 or higher.

[#152]: https://github.com/envato/double_entry/pull/152
[#154]: https://github.com/envato/double_entry/pull/154

## [1.0.1] - 2018-01-06

### Removed

- Removed Rubocop checks and build step.

### Fixed

- Use `Money#positive?` and `Money#negative?` rather than comparing to zero.
  Resolves issues when dealing with multiple currencies.

- Fixed typo in jack_hammer documentation.

## [1.0.0] - 2015-08-04

### Added

- Record meta-data against transfers.

    ```ruby
    DoubleEntry.transfer(
      Money.new(20_00),
      :from     => one_account,
      :to       => another_account,
      :code     => :a_business_code_for_this_type_of_transfer,
      :metadata => { :key1 => 'value 1', :key2 => 'value 2' },
    )
    ```

  This feature requires a new DB table. Please add a migration similar to:

    ```ruby
    class CreateDoubleEntryLineMetadata < ActiveRecord::Migration
      def self.up
        create_table "#{DoubleEntry.table_name_prefix}line_metadata", :force => true do |t|
          t.integer    "line_id",               :null => false
          t.string     "key",     :limit => 48, :null => false
          t.string     "value",   :limit => 64, :null => false
          t.timestamps                          :null => false
        end

        add_index "#{DoubleEntry.table_name_prefix}line_metadata",
                  ["line_id", "key", "value"],
                  :name => "lines_meta_line_id_key_value_idx"
      end

      def self.down
        drop_table "#{DoubleEntry.table_name_prefix}line_metadata"
      end
    end
    ```

### Changed

- Raise `DoubleEntry::Locking::LockWaitTimeout` for lock wait timeouts.

### Fixed

- Ensure that a range is specified when performing an aggregate function over
  lines.

## [0.10.3] - 2015-07-15

### Added

- Check code format with Rubocop as part of the CI build.

### Fixed

- More Rubocop code formatting issues fixed.

## [0.10.2] - 2015-07-10

### Fixed

- `DoubleEntry::Reporting::AggregateArray` correctly retreives previously
  calculated aggregates.

## [0.10.1] - 2015-07-06

### Added

- Run CI build against Ruby 2.2.0.

- Added Rubocop and resolved code formatting issues.

### Changed

- Reduced permutations of DB, Ruby and Rails in CI build.

- Build status badge displayed in README reports on just the master branch.

- Update RSpec configuration with latest recommended options.

### Fixed

- Addressed Ruby warnings.

- Fixed circular arg reference.

## [0.10.0] - 2015-01-09

### Added

- Define accounts that can be negative only.

    ```ruby
    DoubleEntry.configure do |config|
      config.define_accounts do |accounts|
        accounts.define(
          :identifier     => :my_account_that_never_goes_positive,
          :negative_only  => true
        )
      end
    end
    ```

- Run CI build against Rails 4.2

## [0.9.0] - 2014-12-08

### Changed

- `DoubleEntry::Reporting::Agregate#formated_amount` no longer accepts
  `currency` argument.

## [0.8.0] - 2014-11-19

### Added

- Log when we encounter deadlocks causing restart/retry.

## [0.7.2] - 2014-11-18

### Removed

- Removed `DoubleEntry::currency` method.

## [0.7.1] - 2014-11-17

### Fixed

- `DoubleEntry::balance` and `DoubleEntry::account` now raise
  `DoubleEntry::AccountScopeMismatchError` if the scope provided is not of
  the same type in the account definition.

- Speed up CI build.

## [0.7.0] - 2014-11-12

### Added

- Added support for currency. :money_with_wings:

### Changed

- Require at least version 6.0 of Money gem.

## [0.6.1] - 2014-10-10

### Changed

- Removed use of Active Record callbacks in `DoubleEntry::Line`.

- Changed `DoubleEntry::Reporting::WeekRange` calculation to use
`Date#cweek`.

## [0.6.0] - 2014-08-23

### Fixed

- Fixed defect preventing locking a scoped and a non scoped account.

## [0.5.0] - 2014-08-01

### Added

- Added a convenience method for defining active record scope identifiers.

    ```ruby
    DoubleEntry.configure do |config|
      config.define_accounts do |accounts|
        user_scope = accounts.active_record_scope_identifier(User)
        accounts.define(:identifier => :checking, :scope_identifier => user_scope)
      end
    end
    ```

- Added support for SQLite.

### Removed

- Removed errors: `DoubleEntry::RequiredMetaMissing` and
`DoubleEntry::UserAccountNotLocked`.

### Fixed

- Fixed `Reporting::reconciled?` support for account scopes.

## [0.4.0] - 2014-07-17

### Added

- Added Yardoc documention to the `DoubleEntry::balance` method.

### Changed

- Changed `Line#debit?` to `Line#increase?` and `Line#credit?` to
  `Line#decrease?`.

### Removed

- Removed the `DoubleEntry::Line#meta` attribute.

## [0.3.1] - 2014-07-11

### Fixed

- Obtain a year range array without prioviding a start date.

## [0.3.0] - 2014-07-11

### Added

- Add Yardoc to `Reporting` module.
- Allow reporting month and year time ranges without a start date.

### Changed

- Use ruby18 hash syntax for configuration example in README.

### Removed

- Removed `DoubleEntry::describe` and `DoubleEntry::Line#description`
  methods.

## [0.2.0] - 2014-06-28

### Added

- Added a configuration class to define valid accounts and transfers.

    ```ruby
    DoubleEntry.configure do |config|
      config.define_accounts do |accounts|
        accounts.define(identifier: :savings,  positive_only: true)
        accounts.define(identifier: :checking)
      end

      config.define_transfers do |transfers|
        transfers.define(from: :checking, to: :savings,  code: :deposit)
        transfers.define(from: :savings,  to: :checking, code: :withdraw)
      end
    end
    ```

### Changed

- Move reporting classes into the `DoubleEntry::Reporting` namespace. Mark
  this module as `@api private`: internal use only.

## 0.1.0 - 2014-06-20

### Added

- Library released as Open Source!

[2.0.0.beta5]: https://github.com/envato/double_entry/compare/v2.0.0.beta4...v2.0.0.beta5
[2.0.0.beta4]: https://github.com/envato/double_entry/compare/v2.0.0.beta3...v2.0.0.beta4
[2.0.0.beta3]: https://github.com/envato/double_entry/compare/v2.0.0.beta2...v2.0.0.beta3
[2.0.0.beta2]: https://github.com/envato/double_entry/compare/v2.0.0.beta1...v2.0.0.beta2
[2.0.0.beta1]: https://github.com/envato/double_entry/compare/v1.0.1...v2.0.0.beta1
[1.0.1]: https://github.com/envato/double_entry/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/envato/double_entry/compare/v0.10.3...v1.0.0
[0.10.3]: https://github.com/envato/double_entry/compare/v0.10.2...v0.10.3
[0.10.2]: https://github.com/envato/double_entry/compare/v0.10.1...v0.10.2
[0.10.1]: https://github.com/envato/double_entry/compare/v0.10.0...v0.10.1
[0.10.0]: https://github.com/envato/double_entry/compare/v0.9.0...v0.10.0
[0.9.0]: https://github.com/envato/double_entry/compare/v0.8.0...v0.9.0
[0.8.0]: https://github.com/envato/double_entry/compare/v0.7.2...v0.8.0
[0.7.2]: https://github.com/envato/double_entry/compare/v0.7.1...v0.7.2
[0.7.1]: https://github.com/envato/double_entry/compare/v0.7.0...v0.7.1
[0.7.0]: https://github.com/envato/double_entry/compare/v0.6.1...v0.7.0
[0.6.1]: https://github.com/envato/double_entry/compare/v0.6.0...v0.6.1
[0.6.0]: https://github.com/envato/double_entry/compare/v0.5.0...v0.6.0
[0.5.0]: https://github.com/envato/double_entry/compare/v0.4.0...v0.5.0
[0.4.0]: https://github.com/envato/double_entry/compare/v0.3.1...v0.4.0
[0.3.1]: https://github.com/envato/double_entry/compare/v0.3.0...v0.3.1
[0.3.0]: https://github.com/envato/double_entry/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/envato/double_entry/compare/v0.1.0...v0.2.0
