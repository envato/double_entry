# DoubleEntry

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

Ruby Versions: 1.9.3

Rails Versions: Rails 4

--

**Databases Supported:**
 * MySQL
 * PostgreSQL


## Installation

In your application's `Gemfile`, add:

    gem 'double_entry'

Then run:

    bundle
    rails generate double_entry:install

Run migration files:

    rake db:migrate


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

    account = DoubleEntry.account(:spending, :scope => user)

(This actually returns an Account::Instance object.)

See **DoubleEntry::Account** for more info.


### Balances

Calling:

    account.balance

will return the current balance for an account as a Money object.


### Transfers

To transfer money between accounts:

    DoubleEntry.transfer(20.dollars, :from => account_a, :to => account_b, :code => :purchase)

The possible transfers, and their codes, should be defined in the configuration.

See **DoubleEntry::Transfer** for more info.


### Locking

If you're doing more than one transfer in a single financial transaction, or
you're doing other database operations along with the transfer, you'll need to
manually lock the accounts you're using:

    DoubleEntry.lock_accounts(account_a, account_b) do
      # Do some other stuff in here...
      DoubleEntry.transfer(20.dollars, :from => account_a, :to => account_b, :code => :purchase)
    end

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

For example, the following specifies two accounts, account_a and account_b.
Each account is scoped by User (where User is an object with an ID), meaning
each user can have their own account of each type.

This configuration also specifies that money can be transferred between the two accounts.

    require 'double_entry'

    DoubleEntry.accounts = DoubleEntry::Account::Set.new do
      @user_scope = lambda do |user|
        if user.is_a?(User)
          user.id
        end
      end

      double_entry/account(:identifier => :account_a, :scope_identifier => @user_scope, :positive_only => false)
      double_entry/account(:identifier => :account_b, :scope_identifier => @user_scope)
    end

    DoubleEntry.transfers = DoubleEntry::Transfer::Set.new do
      double_entry/transfer(:from => :account_a, :to => :account_b, :code => :deposit)
      double_entry/transfer(:from => :account_b, :to => :account_a, :code => :withdrawal)
    end

## Jackhammer

Run a concurrency test on the code.

This spawns a bunch of processes, and does random transactions between a set
of accounts, then validates that all the numbers add up at the end.

You can also tell out it to flush out the account balances table at regular
intervals, to validate that new account balances records get created with the
correct balances from the lines table.

    ./script/jack_hammer -t 20                                                                                                                                    finance3/git/master
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

No immediate to-do's.

## Development Environment Setup

1. Clone this repo.

        git clone git@github.com:envato/double_entry.git && cd double_entry

2. Run the included setup script to install the gem dependencies.

        ./script/setup.sh

3. Install MySQL and PostgreSQL. The tests run using both databases.
4. Create a database in MySQL.

        mysql -u root -e 'create database double_entry_test;'

5. Create a database in PostgreSQL.

        psql -c 'create database double_entry_test;' -U postgres

6. Specify how the tests should connect to the database

        cp spec/support/{database.example.yml, database.yml}
        vim spec/support/database.yml

7. Run the tests

        bundle exec rake

