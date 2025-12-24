# frozen_string_literal: true

RSpec.describe RSpec::Clickhouse::Helpers do
  describe ".quote_clickhouse_value" do
    it "quotes strings" do
      expect(described_class.quote_clickhouse_value("test")).to eq("'test'")
    end

    it "escapes single quotes in strings" do
      expect(described_class.quote_clickhouse_value("it's")).to eq("'it''s'")
    end

    it "handles arrays" do
      expect(described_class.quote_clickhouse_value([1, 2, 3])).to eq("[1, 2, 3]")
    end

    it "handles string arrays" do
      expect(described_class.quote_clickhouse_value(['a', 'b'])).to eq("['a', 'b']")
    end

    it "converts booleans to 1/0" do
      expect(described_class.quote_clickhouse_value(true)).to eq('1')
      expect(described_class.quote_clickhouse_value(false)).to eq('0')
    end

    it "handles nil as NULL" do
      expect(described_class.quote_clickhouse_value(nil)).to eq('NULL')
    end

    it "formats dates" do
      date = Date.new(2024, 1, 15)
      expect(described_class.quote_clickhouse_value(date)).to eq("'2024-01-15 00:00:00'")
    end

    it "converts numbers to strings" do
      expect(described_class.quote_clickhouse_value(123)).to eq('123')
      expect(described_class.quote_clickhouse_value(45.67)).to eq('45.67')
    end
  end
end
