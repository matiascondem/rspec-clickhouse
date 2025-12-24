# frozen_string_literal: true

require 'integration_helper'

RSpec.describe 'Test Infrastructure', type: :integration do
  describe RSpec::Clickhouse::TestHelper do
    before(:each) do
      # Truncate first to ensure clean state
      described_class.truncate_all_tables!

      # Insert some test data
      RSpec::Clickhouse.execute(<<~SQL)
        INSERT INTO test_facts (id, name, value, tags, active, created_at)
        VALUES (1, 'Fact 1', 100, [], 1, now()),
               (2, 'Fact 2', 200, [], 1, now())
      SQL

      RSpec::Clickhouse.execute(<<~SQL)
        INSERT INTO user_events (id, user_id, event_type, event_data, timestamp)
        VALUES (1, 100, 'click', 'button_a', now())
      SQL
    end

    describe '.truncate_all_tables!' do
      it 'truncates all tables' do
        # Verify data exists
        facts = RSpec::Clickhouse.select('SELECT COUNT(*) as cnt FROM test_facts')
        events = RSpec::Clickhouse.select('SELECT COUNT(*) as cnt FROM user_events')
        expect(facts.first['cnt']).to eq(2)
        expect(events.first['cnt']).to eq(1)

        # Truncate
        described_class.truncate_all_tables!

        # Verify data is gone
        facts = RSpec::Clickhouse.select('SELECT COUNT(*) as cnt FROM test_facts')
        events = RSpec::Clickhouse.select('SELECT COUNT(*) as cnt FROM user_events')
        expect(facts.first['cnt']).to eq(0)
        expect(events.first['cnt']).to eq(0)
      end

      it 'does not truncate views' do
        # Should not raise an error trying to truncate views
        expect { described_class.truncate_all_tables! }.not_to raise_error
      end
    end

    describe '.available?' do
      it 'returns true when ClickHouse is available' do
        expect(described_class.available?).to be true
      end
    end

    describe '.ensure_available!' do
      it 'does not raise when ClickHouse is available' do
        expect { described_class.ensure_available! }.not_to raise_error
      end
    end
  end
end
