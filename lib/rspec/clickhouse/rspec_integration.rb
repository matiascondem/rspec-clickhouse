# frozen_string_literal: true

module RSpec
  module Clickhouse
    module RSpecIntegration
      class << self
        def setup!
          return unless defined?(::RSpec)

          ::RSpec.configure do |config|
            setup_before_suite(config)
            setup_before_each(config)
            include_helpers(config)
          end
        end

        private

        def setup_before_suite(config)
          config.before(:suite) do
            # Ensure ClickHouse is available
            RSpec::Clickhouse::TestHelper.ensure_available!

            # Check if schema exists
            check_table = RSpec::Clickhouse.configuration.availability_check_table
            if check_table && !RSpec::Clickhouse.table_exists?(check_table)
              logger = RSpec::Clickhouse.configuration.logger
              logger&.info 'ClickHouse schema not found, loading...'
              RSpec::Clickhouse::SchemaManager.load_schema
            end
          rescue RSpec::Clickhouse::TestHelper::ClickHouseUnavailableError => e
            raise e
          rescue StandardError => e
            raise RSpec::Clickhouse::TestHelper::ClickHouseUnavailableError,
                  "Failed to prepare ClickHouse: #{e.message}\n\n" \
                  'Try: bundle exec rake clickhouse:test:prepare'
          end

          # Log database being used
          config.before(:suite) do
            db_name = RSpec::Clickhouse.database_name
            logger = RSpec::Clickhouse.configuration.logger
            logger&.info "ClickHouse tests using database: #{db_name}"
          end
        end

        def setup_before_each(config)
          metadata_key = RSpec::Clickhouse.configuration.auto_truncate_metadata

          config.before(:each, metadata_key => true) do
            RSpec::Clickhouse::TestHelper.truncate_all_tables!
          end
        end

        def include_helpers(config)
          config.include RSpec::Clickhouse::Helpers,
                         RSpec::Clickhouse.configuration.auto_truncate_metadata => true
        end

        def log_info(message)
          logger = RSpec::Clickhouse.configuration.logger
          logger&.info(message)
        end
      end
    end
  end
end
