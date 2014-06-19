# encoding: utf-8
require "spec_helper"
describe DoubleEntry::Reporting do

  describe "::configure" do
    after { DoubleEntry::Reporting.instance_variable_set(:@configuration, nil) }

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

end
