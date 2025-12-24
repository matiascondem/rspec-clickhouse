# frozen_string_literal: true

module RSpec
  module Clickhouse
    # Singleton accessor for ClickHouse database connections
    #
    # This module provides a centralized, thread-safe way to access ClickHouse connections
    # without having to instantiate a new connection object each time.
    #
    # By default, all methods use the :main database connection unless specified otherwise.
    #
    # @example Basic usage (uses :main database)
    #   RSpec::Clickhouse::Db.select('SELECT count(*) FROM users')
    #   RSpec::Clickhouse::Db.execute('INSERT INTO logs VALUES (1, "test")')
    #   RSpec::Clickhouse::Db.ping
    #
    # @example Using a different database
    #   RSpec::Clickhouse::Db.select('SELECT * FROM data', database: :analytics)
    #   RSpec::Clickhouse::Db.connection(:analytics).select('SELECT * FROM data')
    #
    module Db
      class << self
        # Get a connection to a specific database (memoized per database)
        #
        # @param database [Symbol] Database identifier (defaults to :main)
        # @return [RSpec::Clickhouse::Connection] Singleton connection to specified database
        def connection(database = :main)
          connections[database] ||= begin
            config = client_configuration
            Connection.new(database, config)
          end
        end

        # Execute a SELECT query on the default (:main) database
        #
        # @param query [String] SQL query to execute
        # @param database [Symbol] Database identifier (defaults to :main)
        # @return [Array<Hash>] Query results
        def select(query, database: :main)
          connection(database).select(query)
        end

        # Execute a non-SELECT query on the default (:main) database
        #
        # @param query [String] SQL query to execute
        # @param database [Symbol] Database identifier (defaults to :main)
        # @return [Object] Response from ClickHouse
        def execute(query, database: :main)
          connection(database).execute(query)
        end

        # Check if connection to the default database is alive
        #
        # @param database [Symbol] Database identifier (defaults to :main)
        # @return [Boolean] true if connection is successful
        def ping(database: :main)
          connection(database).ping
        end

        # Get the database name for the specified database
        #
        # @param database [Symbol] Database identifier (defaults to :main)
        # @return [String, nil] Database name
        def database_name(database: :main)
          connection(database).database_name
        end

        # Check if a table exists in the specified database
        #
        # @param table_name [String] Name of the table to check
        # @param database [Symbol] Database identifier (defaults to :main)
        # @return [Boolean] true if table exists
        def table_exists?(table_name, database: :main)
          connection(database).table_exists?(table_name)
        end

        # Reset all connections (useful for testing or after configuration changes)
        #
        # @return [void]
        def reset!
          connections.clear
        end

        private

        def connections
          @connections ||= {}
        end

        def client_configuration
          ClickHouse::Client.configuration
        end
      end
    end
  end
end
