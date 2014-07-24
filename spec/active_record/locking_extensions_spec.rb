# encoding: utf-8
require 'spec_helper'

describe ActiveRecord::LockingExtensions do
  PG_DEADLOCK    = ActiveRecord::StatementInvalid.new("PG::Error: ERROR:  deadlock detected")
  MYSQL_DEADLOCK = ActiveRecord::StatementInvalid.new("Mysql::Error: Deadlock found when trying to get lock")
  SQLITE3_LOCK   = ActiveRecord::StatementInvalid.new("SQLite3::BusyException: database is locked: UPDATE...")

  context "#restartable_transaction" do
    it "keeps running the lock until a ActiveRecord::RestartTransaction isn't raised" do
      expect(User).to receive(:create!).ordered.and_raise(ActiveRecord::RestartTransaction)
      expect(User).to receive(:create!).ordered.and_raise(ActiveRecord::RestartTransaction)
      expect(User).to receive(:create!).ordered.and_return(true)

      expect { User.restartable_transaction { User.create! } }.to_not raise_error
    end
  end

  context "#with_restart_on_deadlock" do
    context "raises a ActiveRecord::RestartTransaction error if a deadlock occurs" do
      it "in mysql" do
        expect { User.with_restart_on_deadlock { raise MYSQL_DEADLOCK } }.to raise_error(ActiveRecord::RestartTransaction)
      end

      it "in postgres" do
        expect { User.with_restart_on_deadlock { raise PG_DEADLOCK } }.to raise_error(ActiveRecord::RestartTransaction)
      end
    end
  end

  context "#create_ignoring_duplicates" do
    it "does not raise an error if a duplicate index error is raised in the database" do
      User.make! :username => "keith"

      expect { User.make! :username => "keith" }.to raise_error
      expect { User.create_ignoring_duplicates! :username => "keith" }.to_not raise_error
    end

    context "retries the creation if a deadlock error is raised from the database" do
      it "in mysql" do
        expect(User).to receive(:create!).ordered.and_raise(MYSQL_DEADLOCK)
        expect(User).to receive(:create!).ordered.and_return(true)

        expect { User.create_ignoring_duplicates! }.to_not raise_error
      end

      it "in postgres" do
        expect(User).to receive(:create!).ordered.and_raise(PG_DEADLOCK)
        expect(User).to receive(:create!).ordered.and_return(true)

        expect { User.create_ignoring_duplicates! }.to_not raise_error
      end

      it "in sqlite3" do
        expect(User).to receive(:create!).ordered.and_raise(SQLITE3_LOCK)
        expect(User).to receive(:create!).ordered.and_return(true)

        expect { User.create_ignoring_duplicates! }.to_not raise_error
      end
    end
  end
end
