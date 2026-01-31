# frozen_string_literal: true

module RSpec
  module Clickhouse
    module RSpecIntegration
      class << self
        def setup!
          return unless defined?(::RSpec)

          ::RSpec.configure do |config|
            setup_lazy_suite_hooks(config)
            setup_before_each(config)
            include_helpers(config)
          end
        end

        private

        # Use when_first_matching_example_defined to lazily set up ClickHouse
        # only when tests with the clickhouse metadata are actually run.
        # This avoids checking ClickHouse availability for non-ClickHouse test runs.
        def setup_lazy_suite_hooks(config)
          metadata_key = RSpec::Clickhouse.configuration.auto_truncate_metadata

          config.when_first_matching_example_defined(metadata_key => true) do
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

              # Log database being used
              db_name = RSpec::Clickhouse.database_name
              logger = RSpec::Clickhouse.configuration.logger
              logger&.info "ClickHouse tests using database: #{db_name}"
            rescue RSpec::Clickhouse::TestHelper::ClickHouseUnavailableError => e
              raise e
            rescue StandardError => e
              raise RSpec::Clickhouse::TestHelper::ClickHouseUnavailableError,
                    "Failed to prepare ClickHouse: #{e.message}\n\n" \
                    'Try: bundle exec rake clickhouse:test:prepare'
            end
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
