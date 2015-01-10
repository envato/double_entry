# encoding: utf-8

RSpec.describe ActiveRecord::LockingExtensions do
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
    shared_examples "abstract adapter" do
      it "raises a ActiveRecord::RestartTransaction error if a deadlock occurs" do
        expect { User.with_restart_on_deadlock { raise exception } }.to raise_error(ActiveRecord::RestartTransaction)
      end

      it "publishes a notification" do
        expect(ActiveSupport::Notifications).to receive(:publish).with("deadlock_restart.active_record", hash_including(:exception => exception))
        expect { User.with_restart_on_deadlock { raise exception } }.to raise_error
      end
    end

    context "mysql" do
      let(:exception) { MYSQL_DEADLOCK }

      it_behaves_like "abstract adapter"
    end

    context "postgres" do
      let(:exception) { PG_DEADLOCK }

      it_behaves_like "abstract adapter"
    end

    context "sqlite" do
      let(:exception) { SQLITE3_LOCK }

      it_behaves_like "abstract adapter"
    end
  end

  context "#create_ignoring_duplicates" do
    it "does not raise an error if a duplicate index error is raised in the database" do
      User.make! :username => "keith"

      expect { User.make! :username => "keith" }.to raise_error
      expect { User.create_ignoring_duplicates! :username => "keith" }.to_not raise_error
    end

    it "publishes a notification when a duplicate is encountered" do
      User.make! :username => "keith"

      expect(ActiveSupport::Notifications).to receive(:publish).with("duplicate_ignore.active_record", hash_including(:exception => kind_of(ActiveRecord::RecordNotUnique)))

      expect { User.create_ignoring_duplicates! :username => "keith" }.to_not raise_error
    end

    shared_examples "abstract adapter" do
      it "retries the creation if a deadlock error is raised from the database" do
        expect(User).to receive(:create!).ordered.and_raise(exception)
        expect(User).to receive(:create!).ordered.and_return(true)

        expect { User.create_ignoring_duplicates! }.to_not raise_error
      end

      it "publishes a notification on each retry" do
        expect(User).to receive(:create!).ordered.and_raise(exception)
        expect(User).to receive(:create!).ordered.and_raise(exception)
        expect(User).to receive(:create!).ordered.and_return(true)

        expect(ActiveSupport::Notifications).to receive(:publish).with("deadlock_retry.active_record", hash_including(:exception => exception)).twice

        expect { User.create_ignoring_duplicates! }.to_not raise_error
      end
    end

    context "mysql" do
      let(:exception) { MYSQL_DEADLOCK }

      it_behaves_like "abstract adapter"
    end

    context "postgres" do
      let(:exception) { PG_DEADLOCK }

      it_behaves_like "abstract adapter"
    end

    context "sqlite" do
      let(:exception) { SQLITE3_LOCK }

      it_behaves_like "abstract adapter"
    end
  end
end
