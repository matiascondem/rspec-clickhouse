# frozen_string_literal: true

require 'integration_helper'

RSpec.describe 'Schema Management', type: :integration do
  before(:each) do
    RSpec::Clickhouse::TestHelper.truncate_all_tables!
  end

  describe RSpec::Clickhouse::SchemaManager do
    it 'loaded all tables from schema' do
      expect(RSpec::Clickhouse.table_exists?('test_facts')).to be true
      expect(RSpec::Clickhouse.table_exists?('user_events')).to be true
    end

    it 'loaded views from schema' do
      # Check if view exists
      result = RSpec::Clickhouse.select(<<~SQL.squish)
        SELECT name FROM system.tables
        WHERE database = 'rspec_clickhouse_test'
          AND name = 'active_facts'
          AND engine = 'View'
      SQL
      expect(result.size).to eq(1)
    end

    it 'can query views' do
      # Insert test data
      RSpec::Clickhouse.execute(<<~SQL)
        INSERT INTO test_facts (id, name, value, tags, active, created_at)
        VALUES (1, 'Active', 100, [], 1, now()),
               (2, 'Inactive', 200, [], 0, now())
      SQL

      # Query view
      result = RSpec::Clickhouse.select('SELECT * FROM active_facts')
      expect(result.size).to eq(1)
      expect(result.first['name']).to eq('Active')
    end
  end
end
