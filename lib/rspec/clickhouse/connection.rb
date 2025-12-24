# frozen_string_literal: true

module RSpec
  module Clickhouse
    # Connection wrapper for ClickHouse database operations
    #
    # This class provides a simplified interface for executing ClickHouse queries
    # without repeating database configuration in every query call.
    #
    # Based on GitLab's ClickHouse::Connection implementation:
    # https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/click_house/connection.rb
    #
    # @example
    #   connection = RSpec::Clickhouse::Connection.new(:main, config)
    #   results = connection.select('SELECT count(*) FROM users')
    #   connection.execute('INSERT INTO logs VALUES (1, "test")')
    #
    class Connection
      attr_reader :database, :configuration

      def initialize(database, configuration)
        @database = database
        @configuration = configuration
      end

      # Execute a SELECT query and return results as an array of hashes
      #
      # Supports both raw SQL strings and parameterized Query objects:
      # @param query [String, ClickHouse::Client::Query] SQL query or Query object to execute
      # @return [Array<Hash>] Query results
      #
      # @example With raw SQL string
      #   connection.select('SELECT count(*) FROM users')
      #
      # @example With parameterized Query object
      #   query = ClickHouse::Client::Query.new(
      #     raw_query: 'SELECT * FROM users WHERE id = {user_id:UInt64}',
      #     placeholders: { user_id: 123 }
      #   )
      #   connection.select(query)
      def select(query)
        ClickHouse::Client.select(query, database, configuration)
      end

      # Execute a non-SELECT query (INSERT, UPDATE, etc.)
      #
      # Supports both raw SQL strings and parameterized Query objects:
      # @param query [String, ClickHouse::Client::Query] SQL query or Query object to execute
      # @return [Object] Response from ClickHouse
      def execute(query)
        ClickHouse::Client.execute(query, database, configuration)
      end

      # Check if connection to ClickHouse is alive
      #
      # @return [Boolean] true if connection is successful
      def ping
        execute('SELECT 1')
        true
      rescue StandardError
        false
      end

      # Get the database name from configuration
      #
      # @return [String, nil] Database name
      def database_name
        configuration.databases[database]&.database
      end

      # Check if a table exists in the database
      #
      # @param table_name [String] Name of the table to check
      # @return [Boolean] true if table exists
      def table_exists?(table_name)
        # Note: Using string interpolation here. In v2, consider using parameterized queries
        # if click_house-client supports it for system table queries
        query = <<~SQL.squish
          SELECT 1
          FROM system.tables
          WHERE database = '#{database_name}'
            AND name = '#{table_name}'
          LIMIT 1
        SQL

        result = select(query)
        result.any?
      rescue StandardError
        false
      end
    end
  end
end
