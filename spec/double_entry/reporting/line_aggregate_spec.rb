# encoding: utf-8
module DoubleEntry::Reporting
  describe LineAggregate do

    it "has a table name prefixed with double_entry_" do
      expect(LineAggregate.table_name).to eq "double_entry_line_aggregates"
    end
  end
end
