# encoding: utf-8
module DoubleEntry
  module Reporting
    RSpec.describe LineAggregate do
      describe '.table_name' do
        subject { LineAggregate.table_name }
        it { should eq('double_entry_line_aggregates') }
      end
    end
  end
end
