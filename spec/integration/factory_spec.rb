# frozen_string_literal: true

require 'integration_helper'

RSpec.describe 'Factory System', type: :integration do
  before(:each) do
    RSpec::Clickhouse::TestHelper.truncate_all_tables!
    RSpec::Clickhouse::FactoryRegistry.clear!
  end

  describe 'creating data with factories' do
    before do
      RSpec::Clickhouse.define_factory :test_fact, table: 'test_facts' do
        sequence(:id)
        name 'Test Fact' # Simple string for now
        value { 100 }
        tags { ['tag1', 'tag2'] }
        active { 1 }
        created_at { Time.new(2024, 1, 1, 12, 0, 0) }

        trait :inactive do
          active { 0 }
        end

        trait :high_value do
          value { 1000 }
        end
      end
    end

    it 'creates a record in ClickHouse' do
      create_clickhouse(:test_fact)

      result = RSpec::Clickhouse.select('SELECT * FROM test_facts')
      expect(result.size).to eq(1)
      expect(result.first['name']).to eq('Test Fact')
      expect(result.first['value']).to eq(100)
    end

    it 'supports sequences' do
      create_clickhouse(:test_fact)
      create_clickhouse(:test_fact)
      create_clickhouse(:test_fact)

      result = RSpec::Clickhouse.select('SELECT id FROM test_facts ORDER BY id')
      expect(result.map { |r| r['id'] }).to eq([1, 2, 3])
    end

    it 'supports attribute overrides' do
      create_clickhouse(:test_fact, name: 'Custom Name', value: 999)

      result = RSpec::Clickhouse.select('SELECT * FROM test_facts')
      expect(result.first['name']).to eq('Custom Name')
      expect(result.first['value']).to eq(999)
    end

    it 'supports traits' do
      create_clickhouse(:test_fact, :inactive)

      result = RSpec::Clickhouse.select('SELECT active FROM test_facts')
      expect(result.first['active']).to eq(0)
    end

    it 'supports multiple traits' do
      create_clickhouse(:test_fact, :inactive, :high_value)

      result = RSpec::Clickhouse.select('SELECT active, value FROM test_facts')
      expect(result.first['active']).to eq(0)
      expect(result.first['value']).to eq(1000)
    end

    it 'supports creating lists' do
      create_clickhouse_list(:test_fact, 10)

      result = RSpec::Clickhouse.select('SELECT COUNT(*) as cnt FROM test_facts')
      expect(result.first['cnt']).to eq(10)
    end

    it 'handles arrays correctly' do
      create_clickhouse(:test_fact, tags: ['custom1', 'custom2', 'custom3'])

      result = RSpec::Clickhouse.select('SELECT tags FROM test_facts')
      expect(result.first['tags']).to eq(['custom1', 'custom2', 'custom3'])
    end
  end

  describe 'helper methods' do
    it 'inserts single records correctly' do
      insert_into_clickhouse('test_facts', {
        id: 1,
        name: 'Test',
        value: 100,
        tags: ['a', 'b'],
        active: 1,
        created_at: Time.new(2024, 1, 1)
      })

      result = RSpec::Clickhouse.select('SELECT * FROM test_facts')
      expect(result.size).to eq(1)
      expect(result.first['name']).to eq('Test')
    end

    it 'bulk inserts multiple records correctly' do
      rows = 5.times.map do |i|
        {
          id: i + 1,
          name: "Test #{i}",
          value: 100 * i,
          tags: [],
          active: 1,
          created_at: Time.new(2024, 1, 1)
        }
      end

      bulk_insert_into_clickhouse('test_facts', rows)

      result = RSpec::Clickhouse.select('SELECT COUNT(*) as cnt FROM test_facts')
      expect(result.first['cnt']).to eq(5)
    end

    it 'handles special characters in strings' do
      insert_into_clickhouse('test_facts', {
        id: 1,
        name: "It's a test with 'quotes'",
        value: 100,
        tags: [],
        active: 1,
        created_at: Time.new(2024, 1, 1)
      })

      result = RSpec::Clickhouse.select('SELECT name FROM test_facts')
      expect(result.first['name']).to eq("It's a test with 'quotes'")
    end

    it 'handles null values' do
      RSpec::Clickhouse.execute(<<~SQL)
        INSERT INTO test_facts (id, name, value, tags, active, created_at)
        VALUES (1, #{quote_clickhouse_value(nil)}, 100, [], 1, now())
      SQL

      result = RSpec::Clickhouse.select('SELECT name FROM test_facts')
      expect(result.first['name']).to eq('')
    end
  end
end
