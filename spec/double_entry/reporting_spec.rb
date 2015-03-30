# encoding: utf-8
RSpec.describe DoubleEntry::Reporting do
  describe "::configure" do
    describe "start_of_business" do
      subject(:start_of_business) { DoubleEntry::Reporting.configuration.start_of_business }

      context "configured to 2011-03-12" do
        before do
          DoubleEntry::Reporting.configure do |config|
            config.start_of_business = Time.new(2011, 3, 12)
          end
        end

        it { should eq Time.new(2011, 3, 12) }
      end

      context "not configured" do
        it { should eq Time.new(1970, 1, 1) }
      end
    end
  end

  describe "::scopes_with_minimum_balance_for_account" do
    subject(:scopes) { DoubleEntry::Reporting.scopes_with_minimum_balance_for_account(minimum_balance, :checking) }

    context "a 'checking' account with balance $100" do
      let!(:user) { User.make!(:checking_balance => Money.new(100_00)) }

      context "when searching for balance $99" do
        let(:minimum_balance) { Money.new(99_00) }
        it { should include user.id }
      end

      context "when searching for balance $100" do
        let(:minimum_balance) { Money.new(100_00) }
        it { should include user.id }
      end

      context "when searching for balance $101" do
        let(:minimum_balance) { Money.new(101_00) }
        it { should_not include user.id }
      end
    end
  end
end
