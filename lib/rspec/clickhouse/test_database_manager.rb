# frozen_string_literal: true

module RSpec
  module Clickhouse
    # Manages ClickHouse test database setup
    # Creates separate test databases for parallel test execution
    #
    # Usage:
    #   RSpec::Clickhouse::TestDatabaseManager.prepare_test_database
    #   RSpec::Clickhouse::TestDatabaseManager.drop_test_database
    module TestDatabaseManager
      class << self
        def prepare_test_database
          config = RSpec::Clickhouse.configuration

          config.all_test_database_names.each do |db_name|
            create_database(db_name)
            load_test_stub_tables(db_name)
            load_schema_for_database(db_name)
          end
        end

        def drop_test_database
          config = RSpec::Clickhouse.configuration

          config.all_test_database_names.each do |db_name|
            drop_database(db_name)
          end
        end

        private

        def create_database(db_name)
          conn = admin_connection
          conn.execute("CREATE DATABASE IF NOT EXISTS #{db_name}")
          log_info "Created test database: #{db_name}"
        end

        def drop_database(db_name)
          conn = admin_connection
          conn.execute("DROP DATABASE IF EXISTS #{db_name}")
          log_info "Dropped test database: #{db_name}"
        end

        def load_test_stub_tables(db_name)
          config = RSpec::Clickhouse.configuration
          return unless config.test_stub_tables_dir

          stub_dir = Pathname.new(config.test_stub_tables_dir)
          return unless stub_dir.exist?

          conn = connection_for_database(db_name)
          SchemaManager.load_sql_files_from_dir(stub_dir, conn, description: 'test stub tables')
        end

        def load_schema_for_database(db_name)
          conn = connection_for_database(db_name)
          SchemaManager.load_schema(connection: conn)
        end

        def connection_for_database(db_name)
          config = RSpec::Clickhouse.configuration

          temp_config = ClickHouse::Client::Configuration.new
          temp_config.register_database(
            :main,
            database: db_name,
            url: config.clickhouse_url,
            username: config.clickhouse_username,
            password: config.clickhouse_password,
            variables: { mutations_sync: 1 }
          )
          temp_config.logger = config.logger
          temp_config.http_post_proc = config.http_post_proc if config.http_post_proc

          Connection.new(:main, temp_config)
        end

        def admin_connection
          # Use first test database for admin operations
          config = RSpec::Clickhouse.configuration
          db_name = config.all_test_database_names.first
          connection_for_database(db_name)
        end

        def log_info(message)
          logger&.info(message)
        end

        def logger
          RSpec::Clickhouse.configuration.logger
        end
      end
    end
  end
end
