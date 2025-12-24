# frozen_string_literal: true

require 'integration_helper'

RSpec.describe 'Connection Management', type: :integration do
  describe RSpec::Clickhouse::Connection do
    let(:connection) { RSpec::Clickhouse.connection }

    it 'can ping ClickHouse' do
      expect(connection.ping).to be true
    end

    it 'returns the correct database name' do
      expect(connection.database_name).to eq('rspec_clickhouse_test')
    end

    it 'can execute SELECT queries' do
      result = connection.select('SELECT 1 as num')
      expect(result).to be_an(Array)
      expect(result.first['num']).to eq(1)
    end

    it 'can execute INSERT queries' do
      connection.execute(<<~SQL)
        INSERT INTO test_facts (id, name, value, tags, active, created_at)
        VALUES (1, 'Test', 100, ['tag1', 'tag2'], 1, now())
      SQL

      result = connection.select('SELECT * FROM test_facts WHERE id = 1')
      expect(result.size).to eq(1)
      expect(result.first['name']).to eq('Test')
    end

    it 'can check if table exists' do
      expect(connection.table_exists?('test_facts')).to be true
      expect(connection.table_exists?('nonexistent_table')).to be false
    end
  end

  describe RSpec::Clickhouse::Db do
    it 'provides singleton access to connections' do
      expect(described_class.ping).to be true
    end

    it 'can execute queries through the singleton' do
      result = described_class.select('SELECT 2 as num')
      expect(result.first['num']).to eq(2)
    end

    it 'returns correct database name' do
      expect(described_class.database_name).to eq('rspec_clickhouse_test')
    end

    it 'can reset connections' do
      described_class.connection # Create connection
      expect { described_class.reset! }.not_to raise_error
      expect(described_class.ping).to be true # Should reconnect
    end
  end
end
