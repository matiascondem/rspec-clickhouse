# frozen_string_literal: true

module RSpec
  module Clickhouse
    # Test helper methods for ClickHouse integration testing
    # Provides data cleanup and availability checking utilities
    #
    # Usage in specs:
    #   RSpec::Clickhouse::TestHelper.truncate_all_tables!
    #   RSpec::Clickhouse::TestHelper.ensure_available!
    module TestHelper
      class ClickHouseUnavailableError < StandardError; end

      class << self
        # Truncate all ClickHouse tables in the current test database
        # This provides test isolation similar to DatabaseCleaner's truncation strategy
        #
        # @param database [Symbol] database identifier (default: :main)
        def truncate_all_tables!(database: :main)
          tables = get_truncatable_tables(database)

          conn = RSpec::Clickhouse.connection(database)
          tables.each do |table_name|
            conn.execute("TRUNCATE TABLE IF EXISTS #{table_name}")
          end
        rescue StandardError => e
          logger = RSpec::Clickhouse.configuration.logger
          logger&.error("Failed to truncate ClickHouse tables: #{e.message}")
          raise e
        end

        # Check if ClickHouse is available for testing
        #
        # @param database [Symbol] database identifier (default: :main)
        # @return [Boolean] true if ClickHouse is accessible
        def available?(database: :main)
          RSpec::Clickhouse.ping(database: database)
        rescue StandardError
          false
        end

        # Ensure ClickHouse is available or fail the test suite with a helpful message
        #
        # @param database [Symbol] database identifier (default: :main)
        # @raise [ClickHouseUnavailableError] if ClickHouse is not accessible
        def ensure_available!(database: :main)
          return if available?(database: database)

          config = RSpec::Clickhouse.configuration
          raise ClickHouseUnavailableError, <<~MSG
            ClickHouse is not available!

            Make sure ClickHouse is running:
              #{config.clickhouse_url}

            Try running:
              bundle exec rake clickhouse:test:prepare
          MSG
        end

        private

        def get_truncatable_tables(database)
          conn = RSpec::Clickhouse.connection(database)
          db_name = conn.database_name

          excluded = RSpec::Clickhouse.configuration.truncate_excluded_tables
          exclusion_clause = excluded.map { |t| "name != '#{t}'" }.join(' AND ')
          exclusion_clause = " AND #{exclusion_clause}" if excluded.any?

          query = <<~SQL
            SELECT name
            FROM system.tables
            WHERE database = '#{db_name}'
              AND engine NOT IN ('View', 'MaterializedView', 'Dictionary')
              #{exclusion_clause}
            ORDER BY name
          SQL

          result = conn.select(query.squish)
          result.map { |row| row['name'] }
        end
      end
    end
  end
end
