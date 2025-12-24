# frozen_string_literal: true

module RSpec
  module Clickhouse
    # Manages ClickHouse schema creation and destruction
    # Loads tables, dictionaries, views, and functions in correct dependency order
    #
    # Usage:
    #   RSpec::Clickhouse::SchemaManager.load_schema
    #   RSpec::Clickhouse::SchemaManager.drop_schema
    module SchemaManager
      class << self
        # Load the complete ClickHouse schema into the specified database
        #
        # @param database [Symbol] database identifier (default: :main)
        # @param connection [RSpec::Clickhouse::Connection, nil] optional connection (for test setup)
        def load_schema(database: :main, connection: nil)
          conn = connection || RSpec::Clickhouse.connection(database)

          validate_schema_root!

          log_info "Loading ClickHouse schema from #{schema_root}"

          load_order.each do |dir_name|
            dir = schema_root.join(dir_name)
            next unless dir.exist?

            load_sql_files_from_dir(dir, conn, description: dir_name)
          end

          log_info "ClickHouse schema loaded successfully"
        end

        # Drop all schema objects from the specified database
        #
        # @param database [Symbol] database identifier (default: :main)
        def drop_schema(database: :main)
          conn = RSpec::Clickhouse.connection(database)
          db_name = conn.database_name

          log_info "Dropping ClickHouse schema from #{db_name}"

          # Drop in reverse dependency order
          drop_dictionaries(conn, db_name)
          drop_views(conn, db_name)
          drop_tables(conn, db_name)

          log_info "ClickHouse schema dropped successfully"
        end

        # Load SQL files from a directory
        #
        # @param dir [Pathname, String] directory containing SQL files
        # @param connection [RSpec::Clickhouse::Connection] connection to execute against
        # @param description [String] description for logging
        def load_sql_files_from_dir(dir, connection, description: nil)
          dir = Pathname.new(dir) unless dir.is_a?(Pathname)
          return unless Dir.exist?(dir)

          files = Dir.glob(dir.join('*.sql')).sort

          # Load dictionary files last (they depend on tables existing)
          regular_files = files.reject { |f| f.end_with?('_dict.sql') }
          dict_files = files.select { |f| f.end_with?('_dict.sql') }

          log_debug "Loading #{files.size} #{description || 'files'} from #{dir}"

          (regular_files + dict_files).each do |file|
            log_debug "  Loading #{File.basename(file)}"
            sql = File.read(file)
            execute_sql(sql, connection)
          end
        end

        # Execute SQL with variable substitution
        #
        # @param sql [String] SQL to execute
        # @param connection [RSpec::Clickhouse::Connection] connection to execute against
        def execute_sql(sql, connection)
          return if sql.strip.empty?

          # Variable substitution
          db_name = connection.database_name
          config = RSpec::Clickhouse.configuration

          substitutions = config.default_variable_substitutions(db_name)
          substitutions.each do |var, value|
            sql = sql.gsub("$#{var}", value)
          end

          connection.execute(sql)
        rescue StandardError => e
          log_error "Failed to execute SQL: #{e.message}"
          log_error "SQL: #{sql[0..200]}..."
          raise
        end

        private

        def schema_root
          root = RSpec::Clickhouse.configuration.schema_root
          raise ConfigurationError, 'schema_root not configured' unless root

          Pathname.new(root)
        end

        def load_order
          RSpec::Clickhouse.configuration.schema_load_order
        end

        def validate_schema_root!
          unless RSpec::Clickhouse.configuration.schema_configured?
            raise ConfigurationError, "schema_root not configured or directory doesn't exist"
          end
        end

        def drop_dictionaries(connection, db_name)
          dictionaries = connection.select(<<~SQL.squish)
            SELECT name
            FROM system.dictionaries
            WHERE database = '#{db_name}'
          SQL

          dictionaries.each do |dict|
            connection.execute("DROP DICTIONARY IF EXISTS #{dict['name']}")
          end
        end

        def drop_views(connection, db_name)
          views = connection.select(<<~SQL.squish)
            SELECT name
            FROM system.tables
            WHERE database = '#{db_name}'
              AND engine = 'View'
          SQL

          views.each do |view|
            connection.execute("DROP VIEW IF EXISTS #{view['name']}")
          end
        end

        def drop_tables(connection, db_name)
          excluded = RSpec::Clickhouse.configuration.excluded_tables_on_drop
          exclusion_clause = excluded.map { |t| "name != '#{t}'" }.join(' AND ')
          where_clause = "database = '#{db_name}' AND engine != 'View'"
          where_clause += " AND #{exclusion_clause}" if excluded.any?

          tables = connection.select(<<~SQL.squish)
            SELECT name
            FROM system.tables
            WHERE #{where_clause}
          SQL

          tables.each do |table|
            connection.execute("DROP TABLE IF EXISTS #{table['name']}")
          end
        end

        def log_info(message)
          logger&.info(message)
        end

        def log_debug(message)
          logger&.debug(message)
        end

        def log_error(message)
          logger&.error(message)
        end

        def logger
          RSpec::Clickhouse.configuration.logger
        end
      end
    end
  end
end
