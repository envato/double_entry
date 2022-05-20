RSpec.describe DoubleEntry::Money do
  it 'delegates singleton methods to the adapter' do
    DoubleEntry::Money.adapter = Class.new do
      def self.zero
        0
      end

      def test
        12345
      end
    end
    expect(DoubleEntry::Money.new.test).to eq(12345)
    expect(DoubleEntry::Money.zero).to eq(0)
    DoubleEntry::Money.adapter = ::Money
  end
end
