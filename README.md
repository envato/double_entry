# DoubleEntry


[![License MIT](https://img.shields.io/badge/license-MIT-brightgreen.svg)](https://github.com/envato/double_entry/blob/master/LICENSE.md)
[![Gem Version](https://badge.fury.io/rb/double_entry.svg)](http://badge.fury.io/rb/double_entry)
[![Build Status](https://github.com/envato/double_entry/actions/workflows/ci-workflow.yml/badge.svg)](https://github.com/envato/double_entry/actions/workflows/ci-workflow.yml)
[![Code Climate](https://codeclimate.com/github/envato/double_entry/badges/gpa.svg)](https://codeclimate.com/github/envato/double_entry)

![Show me the Money](http://24.media.tumblr.com/tumblr_m3bwbqNJIG1rrgbmqo1_500.gif)

Keep track of all the monies!

DoubleEntry is an accounting system based on the principles of a
[Double-entry Bookkeeping](http://en.wikipedia.org/wiki/Double-entry_bookkeeping_system)
system.  While this gem acts like a double-entry bookkeeping system, as it creates
two entries in the database for each transfer, it does *not* enforce accounting rules.

DoubleEntry uses the [Money gem](https://github.com/RubyMoney/money) to encapsulate operations on currency values.

## Compatibility

DoubleEntry is tested against:

Ruby
 * 2.3.x
 * 2.4.x
 * 2.5.x
 * 2.6.x
 * 2.7.x

Rails
 * 4.2.x
 * 5.0.x
 * 5.1.x
 * 5.2.x
 * 6.0.x
 * 6.1.x

Databases
 * MySQL
 * PostgreSQL
 * SQLite

## Installation

In your application's `Gemfile`, add:

```ruby
gem 'double_entry'
```

Download and install the gem with Bundler:

```sh
bundle
```

Generate Rails schema migrations for the required tables:

> The default behavior is to store metadata in a json(b) column rather than a separate `double_entry_line_metadata` table. If you would like the old (1.x) behavior, you can add `--no-json-metadata`.

```sh
rails generate double_entry:install
```

Update the local database:

```sh
rake db:migrate
```


## Interface

The entire API for recording financial transactions is available through a few
methods in the [DoubleEntry](lib/double_entry.rb) module. For full details on
what the API provides, please view the documentation on these methods.

A configuration file should be used to define a set of accounts, and potential
transfers between those accounts.  See the Configuration section for more details.


### Accounts

Money is kept in Accounts.

Each Account has a scope, which is used to subdivide the account into smaller
accounts. For example, an account can be scoped by user to ensure that each
user has their own individual account.

Scoping accounts is recommended.  Unscoped accounts may perform more slowly
than scoped accounts due to lock contention.

To get a particular account:

```ruby
account = DoubleEntry.account(:spending, scope: user)
```

(This actually returns an Account::Instance object.)

See [DoubleEntry::Account](lib/double_entry/account.rb) for more info.


### Balances

Calling:

```ruby
account.balance
```

will return the current balance for an account as a Money object.


### Transfers

To transfer money between accounts:

```ruby
DoubleEntry.transfer(
  Money.new(20_00),
  from: one_account,
  to:   another_account,
  code: :a_business_code_for_this_type_of_transfer,
)
```

The possible transfers, and their codes, should be defined in the configuration.

See [DoubleEntry::Transfer](lib/double_entry/transfer.rb) for more info.

### Metadata

You may associate arbitrary metadata with transfers, for example:

```ruby
DoubleEntry.transfer(
  Money.new(20_00),
  from: one_account,
  to:   another_account,
  code: :a_business_code_for_this_type_of_transfer,
  metadata: {key1: ['value 1', 'value 2'], key2: 'value 3'},
)
```

### Locking

If you're doing more than one transfer in a single financial transaction, or
you're doing other database operations along with the transfer, you'll need to
manually lock the accounts you're using:

```ruby
DoubleEntry.lock_accounts(account_a, account_b) do
  # Perhaps transfer some money
  DoubleEntry.transfer(Money.new(20_00), from: account_a, to: account_b, code: :purchase)
  # Perform other tasks that should be commited atomically with the transfer of funds...
end
```

The lock_accounts call generates a database transaction, which must be the
outermost transaction.

See [DoubleEntry::Locking](lib/double_entry/locking.rb) for more info.

### Account Checker/Fixer

DoubleEntry tries really hard to make sure that stored account balances reflect the running balances from the `double_entry_lines` table, but there is always the unlikely possibility that something will go wrong and the calculated balance might get out of sync with the actual running balance of the lines.

DoubleEntry therefore provides a couple of tools to give you some confidence that things are working as expected.

The `DoubleEntry::Validation::LineCheck` will check the `double_entry_lines` table to make sure that the `balance` column correctly reflects the calculated running balance, and that the `double_entry_account_balances` table has the correct value in the `balance` column. If either one of these turn out to be incorrect then it will write an entry into the `double_entry_line_checks` table reporting on the differences.

You can alternatively pass a `fixer` to the `DoubleEntry::Validation::LineCheck.perform` method which will try and correct the balances. This gem provides the `DoubleEntry::Validation::AccountFixer` class which will correct the balance if it's out of sync.

Using these classes is optional and both are provided for additional safety checks. If you want to make use of them then it's recommended to run them in a scheduled job, somewhere on the order of hourly to daily, depending on transaction volume. Keep in mind that this process locks accounts as it inspects their balances, so it will prevent new transactions from being written for a short time.

Here are examples that could go in your scheduled job, depending on your needs:

```ruby
# Check all accounts & write the results to the double_entry_line_checks table
DoubleEntry::Validation::LineCheck.perform!

# Check & fix accounts (results will also be written to the table)
DoubleEntry::Validation::LineCheck.perform!(fixer: DoubleEntry::Validation::AccountFixer.new)
```

See [DoubleEntry::Validation](lib/double_entry/validation) for more info.

## Implementation

All transfers and balances are stored in the lines table. As this is a
double-entry accounting system, each transfer generates two lines table
entries: one for the source account, and one for the destination.

Lines table entries also store the running balance for the account. To retrieve
the current balance for an account, we find the most recent lines table entry
for it.

See [DoubleEntry::Line](lib/double_entry/line.rb) for more info.

AccountBalance records cache the current balance for each Account, and are used
to perform database level locking.

Transfer metadata is stored in a json(b) column on both the source and destination lines of the transfer.

## Configuration

A configuration file should be used to define a set of accounts, optional scopes on
the accounts, and permitted transfers between those accounts.

The configuration file should be kept in your application's load path.  For example,
*config/initializers/double_entry.rb*. By default, this file will be created when you run the installer, but you will need to fill out your accounts.

For example, the following specifies two accounts, savings and checking.
Each account is scoped by User (where User is an object with an ID), meaning
each user can have their own account of each type.

This configuration also specifies that money can be transferred between the two accounts.

```ruby
require 'double_entry'

DoubleEntry.configure do |config|
  # Use json(b) column in double_entry_lines table to store metadata instead of separate metadata table
  config.json_metadata = true

  config.define_accounts do |accounts|
    user_scope = ->(user) do
      raise 'not a User' unless user.class.name == 'User'
      user.id
    end
    accounts.define(identifier: :savings,  scope_identifier: user_scope, positive_only: true)
    accounts.define(identifier: :checking, scope_identifier: user_scope)
  end

  config.define_transfers do |transfers|
    transfers.define(from: :checking, to: :savings,  code: :deposit)
    transfers.define(from: :savings,  to: :checking, code: :withdraw)
  end
end
```

By default an account's currency is the same as Money.default_currency from the money gem.

You can also specify a currency on a per account basis.
Transfers between accounts of different currencies are not allowed.

```ruby
DoubleEntry.configure do |config|
  config.define_accounts do |accounts|
    accounts.define(identifier: :savings,  scope_identifier: user_scope, currency: 'AUD')
  end
end
```

## Testing with RSpec

Transfering money needs to be run as a top level transaction. This conflicts with RSpec's default behavior of creating a new transaction for every test, causing an exception of type `DoubleEntry::Locking::LockMustBeOutermostTransaction` to be raised. This behavior may be disabled by adding the following lines into your `rails_helper.rb`.

```ruby
RSpec.configure do |config|
  # ...
  # This first line should already be there. You will need to add the second one
  config.use_transactional_fixtures = true
  DoubleEntry::Locking.configuration.running_inside_transactional_fixtures = true
  # ...
end
```

## Jackhammer

Run a concurrency test on the code.

This spawns a bunch of processes, and does random transactions between a set
of accounts, then validates that all the numbers add up at the end.

You can also tell it to flush out the account balances table at regular
intervals, to validate that new account balances records get created with the
correct balances from the lines table.

    ./script/jack_hammer -t 20
    Cleaning out the database...
    Setting up 5 accounts...
    Spawning 20 processes...
    Flushing balances
    Process 1 running 1 transfers...
    Process 0 running 1 transfers...
    Process 3 running 1 transfers...
    Process 2 running 1 transfers...
    Process 4 running 1 transfers...
    Process 5 running 1 transfers...
    Process 6 running 1 transfers...
    Process 7 running 1 transfers...
    Process 8 running 1 transfers...
    Process 9 running 1 transfers...
    Process 10 running 1 transfers...
    Process 11 running 1 transfers...
    Process 12 running 1 transfers...
    Process 13 running 1 transfers...
    Process 14 running 1 transfers...
    Process 16 running 1 transfers...
    Process 15 running 1 transfers...
    Process 17 running 1 transfers...
    Process 19 running 1 transfers...
    Process 18 running 1 transfers...
    Reconciling...
    All the Line records were written, FTW!
    All accounts reconciled, FTW!
    Done successfully :)

## Future Direction

See the Github project [issues](https://github.com/envato/double_entry/issues).

## Development Environment Setup

We're using Docker to provide a convenient and consistent environment for
executing tests during development. This allows engineers to quickly set up
a productive development environment.

Note: Most development files are mounted in the Docker container. This
enables engineers to edit files in their favourite editor (on the host
OS) and have the changes immediately available in the Docker container
to be exercised.

One exception to this is the RSpec configuration. Changes to these files will
require a rebuild of the Docker image (step 2).

Prerequisites:

* Docker
* Docker Compose
* Git

1. Clone this repo.

    ```sh
    git clone git@github.com:envato/double_entry.git && cd double_entry
    ```

2. Build the Docker image we'll use to run tests

    ```sh
    docker-compose build --pull double_entry
    ```

3. Startup a container and attach a terminal. This will also start up a
   MySQL and Postgres database.

    ```sh
    docker-compose run --rm double_entry ash
    ```

4. Run the tests

    ```sh
    DB=mysql bundle exec rspec
    DB=postgres bundle exec rspec
    DB=sqlite bundle exec rspec
    ```

5. When finished, exit the container terminal and shut down the databases.

    ```sh
    exit
    docker-compose down
    ```

## Contributors

Many thanks to those who have contributed to both this gem, and the library upon which it was based, over the years:
  * Anthony Sellitti - @asellitt
  * Clinton Forbes - @clinton
  * Eaden McKee - @eadz
  * Giancarlo Salamanca - @salamagd
  * Jiexin Huang - @jiexinhuang
  * Keith Pitt - @keithpitt
  * Kelsey Hannan - @KelseyDH
  * Mark Turnley - @rabidcarrot
  * Martin Jagusch - @MJIO
  * Martin Spickermann - @spickermann
  * Mary-Anne Cosgrove - @macosgrove
  * Orien Madgwick - @orien
  * Pete Yandall - @notahat
  * Rizal Muthi - @rizalmuthi
  * Ryan Allen - @ryan-allen
  * Samuel Cochran - @sj26
  * Stefan Wrobel - @swrobel
  * Stephanie Staub - @stephnacios
  * Trung Lê - @joneslee85
  * Vahid Ta'eed - @vahid
