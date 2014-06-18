# encoding: utf-8
require 'spec_helper'
describe DoubleEntry::LineAggregate do

  it "has a table name prefixed with double_entry_" do
    expect(DoubleEntry::LineAggregate.table_name).to eq "double_entry_line_aggregates"
  end
end
