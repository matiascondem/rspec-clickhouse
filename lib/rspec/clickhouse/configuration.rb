# frozen_string_literal: true

module RSpec
  module Clickhouse
    class Configuration
      # Connection settings
      attr_accessor :clickhouse_url
      attr_accessor :clickhouse_username
      attr_accessor :clickhouse_password
      attr_accessor :database_name
      attr_accessor :test_database_prefix
      attr_accessor :http_post_proc
      attr_accessor :logger

      # Schema management settings
      attr_accessor :schema_root
      attr_accessor :schema_load_order
      attr_accessor :excluded_tables_on_drop
      attr_accessor :variable_substitutions

      # Test infrastructure settings
      attr_accessor :parallel_test_databases
      attr_accessor :test_stub_tables_dir
      attr_accessor :truncate_excluded_tables
      attr_accessor :auto_truncate_metadata
      attr_accessor :availability_check_table

      # Factory system settings
      attr_accessor :factory_defaults
      attr_accessor :sequence_start

      def initialize
        # Connection defaults
        @clickhouse_url = ENV.fetch('CLICKHOUSE_URL', 'http://localhost:8123')
        @clickhouse_username = ENV.fetch('CLICKHOUSE_USERNAME', 'default')
        @clickhouse_password = ENV.fetch('CLICKHOUSE_PASSWORD', '')
        @database_name = nil # Must be set by app
        @test_database_prefix = nil
        @http_post_proc = nil
        @logger = defined?(Rails) ? Rails.logger : Logger.new($stdout)

        # Schema defaults
        @schema_root = nil # Must be set by app
        @schema_load_order = %w[functions tables views]
        @excluded_tables_on_drop = []
        @variable_substitutions = {}

        # Test defaults
        @parallel_test_databases = ['']
        @test_stub_tables_dir = nil
        @truncate_excluded_tables = []
        @auto_truncate_metadata = :clickhouse
        @availability_check_table = nil

        # Factory defaults
        @factory_defaults = {}
        @sequence_start = 1
      end

      def test_database_name
        return database_name unless test_database_prefix

        test_number = ENV['TEST_ENV_NUMBER']
        "#{test_database_prefix}#{test_number}"
      end

      def all_test_database_names
        parallel_test_databases.map { |suffix| "#{test_database_prefix}#{suffix}" }
      end

      def schema_configured?
        schema_root.present? && File.directory?(schema_root)
      end

      def default_variable_substitutions(db_name)
        {
          'DB_NAME' => db_name,
          'DB_USER' => clickhouse_username,
          'DB_PASSWORD' => clickhouse_password
        }.merge(variable_substitutions)
      end
    end

    class << self
      attr_writer :configuration

      def configuration
        @configuration ||= Configuration.new
      end

      def configure
        yield(configuration)
      end

      # Proxy methods to Db module
      def connection(database = :main)
        Db.connection(database)
      end

      def select(query, database: :main)
        Db.select(query, database: database)
      end

      def execute(query, database: :main)
        Db.execute(query, database: database)
      end

      def ping(database: :main)
        Db.ping(database: database)
      end

      def reset!
        Db.reset!
      end

      def database_name(database: :main)
        Db.database_name(database: database)
      end

      def table_exists?(table_name, database: :main)
        Db.table_exists?(table_name, database: database)
      end
    end
  end
end
