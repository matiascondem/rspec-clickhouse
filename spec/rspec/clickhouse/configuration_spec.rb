# frozen_string_literal: true

RSpec.describe RSpec::Clickhouse::Configuration do
  subject(:config) { described_class.new }

  describe "#initialize" do
    it "sets default values" do
      expect(config.clickhouse_url).to eq('http://localhost:8123')
      expect(config.clickhouse_username).to eq('default')
      expect(config.schema_load_order).to eq(%w[functions tables views])
      expect(config.auto_truncate_metadata).to eq(:clickhouse)
      expect(config.sequence_start).to eq(1)
    end
  end

  describe "#test_database_name" do
    context "when test_database_prefix is not set" do
      it "returns database_name" do
        config.database_name = 'mydb'
        expect(config.test_database_name).to eq('mydb')
      end
    end

    context "when test_database_prefix is set" do
      before do
        config.test_database_prefix = 'mydb_test'
      end

      it "returns prefix with TEST_ENV_NUMBER" do
        allow(ENV).to receive(:[]).with('TEST_ENV_NUMBER').and_return('2')
        expect(config.test_database_name).to eq('mydb_test2')
      end

      it "returns prefix without number when TEST_ENV_NUMBER is nil" do
        allow(ENV).to receive(:[]).with('TEST_ENV_NUMBER').and_return(nil)
        expect(config.test_database_name).to eq('mydb_test')
      end
    end
  end

  describe "#all_test_database_names" do
    it "returns array of database names with suffixes" do
      config.test_database_prefix = 'mydb_test'
      config.parallel_test_databases = ['', '2', '3']

      expect(config.all_test_database_names).to eq([
        'mydb_test',
        'mydb_test2',
        'mydb_test3'
      ])
    end
  end

  describe "#schema_configured?" do
    it "returns false when schema_root is nil" do
      config.schema_root = nil
      expect(config.schema_configured?).to be false
    end

    it "returns false when schema_root directory doesn't exist" do
      config.schema_root = '/nonexistent/path'
      expect(config.schema_configured?).to be false
    end

    it "returns true when schema_root directory exists" do
      config.schema_root = __dir__
      expect(config.schema_configured?).to be true
    end
  end

  describe "#default_variable_substitutions" do
    it "returns hash with DB variables" do
      config.clickhouse_username = 'testuser'
      config.clickhouse_password = 'testpass'

      result = config.default_variable_substitutions('testdb')

      expect(result).to include(
        'DB_NAME' => 'testdb',
        'DB_USER' => 'testuser',
        'DB_PASSWORD' => 'testpass'
      )
    end

    it "merges custom variable substitutions" do
      config.variable_substitutions = { 'CUSTOM_VAR' => 'custom_value' }

      result = config.default_variable_substitutions('testdb')

      expect(result['CUSTOM_VAR']).to eq('custom_value')
    end
  end
end
