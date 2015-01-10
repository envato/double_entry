# encoding: utf-8
describe DoubleEntry::Line do
  it "has a table name prefixed with double_entry_" do
    expect(DoubleEntry::Line.table_name).to eq "double_entry_lines"
  end

  describe "persistance" do
    let(:line_to_persist) {
      DoubleEntry::Line.new(
        :amount => Money.new(10_00),
        :balance => Money.zero,
        :account => account,
        :partner_account => partner_account,
        :code => code,
      )
    }
    let(:account) { DoubleEntry.account(:test, :scope => "17") }
    let(:partner_account) { DoubleEntry.account(:test, :scope => "72") }
    let(:code) { :test_code }

    subject(:persisted_line) do
      line_to_persist.save!
      line_to_persist.reload
    end

    describe "attributes" do
      context "given code = :the_code" do
        let(:code) { :the_code }
        its(:code) { should eq :the_code }
      end

      context "given code = nil" do
        let(:code) { nil }
        specify { expect { line_to_persist.save! }.to raise_error }
      end

      context "given account = :test, 54 " do
        let(:account) { DoubleEntry.account(:test, :scope => "54") }
        its("account.account.identifier") { should eq :test }
        its("account.scope") { should eq "54" }
      end

      context "given partner_account = :test, 91 " do
        let(:partner_account) { DoubleEntry.account(:test, :scope => "91") }
        its("partner_account.account.identifier") { should eq :test }
        its("partner_account.scope") { should eq "91" }
      end

      context "currency" do
        let(:account) { DoubleEntry.account(:btc_test, :scope => "17") }
        let(:partner_account) { DoubleEntry.account(:btc_test, :scope => "72") }
        its(:currency) { should eq "BTC" }
      end
    end

    context 'when balance is sent negative' do
      before { DoubleEntry::Account.accounts.define(:identifier => :a_positive_only_acc, :positive_only => true) }
      let(:account) { DoubleEntry.account(:a_positive_only_acc) }
      let(:line) { DoubleEntry::Line.new(:balance => Money.new(-1), :account => account) }

      it 'raises AccountWouldBeSentNegative error' do
        expect { line.save }.to raise_error DoubleEntry::AccountWouldBeSentNegative
      end
    end

    context 'when balance is sent positive' do
      before { DoubleEntry::Account.accounts.define(:identifier => :a_negative_only_acc, :negative_only => true) }
      let(:account) { DoubleEntry.account(:a_negative_only_acc) }
      let(:line) { DoubleEntry::Line.new(:balance => Money.new(1), :account => account) }

      it 'raises AccountWouldBeSentPositiveError' do
        expect { line.save }.to raise_error DoubleEntry::AccountWouldBeSentPositiveError
      end
    end

    it "has a table name prefixed with double_entry_" do
      expect(DoubleEntry::Line.table_name).to eq "double_entry_lines"
    end
  end
end
