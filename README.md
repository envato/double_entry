# DoubleEntry

Test

[![Gem Version](https://badge.fury.io/rb/double_entry.svg)](http://badge.fury.io/rb/double_entry)
[![Build Status](https://travis-ci.org/envato/double_entry.svg)](https://travis-ci.org/envato/double_entry)
[![Code Climate](https://codeclimate.com/github/envato/double_entry.png)](https://codeclimate.com/github/envato/double_entry)

![Show me the Money](http://24.media.tumblr.com/tumblr_m3bwbqNJIG1rrgbmqo1_500.gif)

Keep track of all the monies!

DoubleEntry is an accounting system based on the principles of a
[Double-entry Bookkeeping](http://en.wikipedia.org/wiki/Double-entry_bookkeeping_system)
system.  While this gem acts like a double-entry bookkeeping system, as it creates
two entries in the database for each transfer, it does *not* enforce accounting rules.

DoubleEntry uses the Money gem to avoid floating point rounding errors.

## Compatibility

DoubleEntry has been tested with:

Ruby Versions: 1.9.3, 2.0.0, 2.1.2

Rails Versions: Rails 3.2.x, 4.0.x, 4.1.x

**Databases Supported:**
 * MySQL
 * PostgreSQL

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

```sh
rails generate double_entry:install
```

Update the local database:

```sh
rake db:migrate
```


## Interface

The entire API for recording financial transactions is available through a few
methods in the **DoubleEntry** module. For full details on
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
account = DoubleEntry.account(:spending, :scope => user)
```

(This actually returns an Account::Instance object.)

See **DoubleEntry::Account** for more info.


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
  20.dollars,
  :from => one_account,
  :to   => another_account,
  :code => :a_business_code_for_this_type_of_transfer,
)
```

The possible transfers, and their codes, should be defined in the configuration.

See **DoubleEntry::Transfer** for more info.


### Locking

If you're doing more than one transfer in a single financial transaction, or
you're doing other database operations along with the transfer, you'll need to
manually lock the accounts you're using:

```ruby
DoubleEntry.lock_accounts(account_a, account_b) do
  # Perhaps transfer some money
  DoubleEntry.transfer(20.dollars, :from => account_a, :to => account_b, :code => :purchase)
  # Perform other tasks that should be commited atomically with the transfer of funds...
end
```

The lock_accounts call generates a database transaction, which must be the
outermost transaction.

See **DoubleEntry::Locking** for more info.


## Implementation

All transfers and balances are stored in the lines table. As this is a
double-entry accounting system, each transfer generates two lines table
entries: one for the source account, and one for the destination.

Lines table entries also store the running balance for the account. To retrieve
the current balance for an account, we find the most recent lines table entry
for it.

See **DoubleEntry::Line** for more info.

AccountBalance records cache the current balance for each Account, and are used
to perform database level locking.

## Configuration

A configuration file should be used to define a set of accounts, optional scopes on
the accounts, and permitted transfers between those accounts.

The configuration file should be kept in your application's load path.  For example,
*config/initializers/double_entry.rb*

For example, the following specifies two accounts, savings and checking.
Each account is scoped by User (where User is an object with an ID), meaning
each user can have their own account of each type.

This configuration also specifies that money can be transferred between the two accounts.

```ruby
require 'double_entry'

DoubleEntry.configure do |config|
  config.define_accounts do |accounts|
    user_scope = accounts.active_record_scope_identifier(User)
    accounts.define(:identifier => :savings,  :scope_identifier => user_scope, :positive_only => true)
    accounts.define(:identifier => :checking, :scope_identifier => user_scope)
  end

  config.define_transfers do |transfers|
    transfers.define(:from => :checking, :to => :savings,  :code => :deposit)
    transfers.define(:from => :savings,  :to => :checking, :code => :withdraw)
  end
end
```

## Jackhammer

Run a concurrency test on the code.

This spawns a bunch of processes, and does random transactions between a set
of accounts, then validates that all the numbers add up at the end.

You can also tell out it to flush out the account balances table at regular
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

1. Clone this repo.

    ```sh
    git clone git@github.com:envato/double_entry.git && cd double_entry
    ```

2. Run the included setup script to install the gem dependencies.

    ```sh
    ./script/setup.sh
    ```

3. Install MySQL and PostgreSQL. We run tests against both databases.
4. Create a database in MySQL.

    ```sh
    mysql -u root -e 'create database double_entry_test;'
    ```

5. Create a database in PostgreSQL.

    ```sh
    psql -c 'create database double_entry_test;' -U postgres
    ```

6. Specify how the tests should connect to the database

    ```sh
    cp spec/support/{database.example.yml,database.yml}
    vim spec/support/database.yml
    ```

7. Run the tests

    ```sh
    bundle exec rake
    ```

