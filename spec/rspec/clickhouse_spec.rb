# frozen_string_literal: true

RSpec.describe RSpec::Clickhouse do
  it "has a version number" do
    expect(RSpec::Clickhouse::VERSION).not_to be nil
  end

  describe ".configuration" do
    it "returns a Configuration instance" do
      expect(described_class.configuration).to be_a(RSpec::Clickhouse::Configuration)
    end
  end

  describe ".configure" do
    it "yields the configuration" do
      expect { |b| described_class.configure(&b) }.to yield_with_args(RSpec::Clickhouse::Configuration)
    end

    it "allows setting configuration values" do
      described_class.configure do |config|
        config.database_name = 'test_db'
      end

      expect(described_class.configuration.database_name).to eq('test_db')
    end
  end
end
