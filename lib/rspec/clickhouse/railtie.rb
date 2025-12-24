# frozen_string_literal: true

module RSpec
  module Clickhouse
    class Railtie < ::Rails::Railtie
      # Run after all user-defined initializers to allow app to configure ClickHouse client
      initializer 'rspec.clickhouse.configure_client', after: :load_config_initializers do
        config = RSpec::Clickhouse.configuration

        # Only auto-configure if no custom configuration is present
        # Skip if already configured (e.g., by app initializer)
        unless ClickHouse::Client.configuration.databases.key?(:main)
          ClickHouse::Client.configure do |client_config|
            database_name = ::Rails.env.test? ? config.test_database_name : config.database_name

            client_config.register_database(
              :main,
              database: database_name,
              url: config.clickhouse_url,
              username: config.clickhouse_username,
              password: config.clickhouse_password,
              variables: { mutations_sync: 1 }
            )

            client_config.logger = config.logger
            client_config.http_post_proc = config.http_post_proc if config.http_post_proc
          end
        end
      end

      rake_tasks do
        load 'tasks/rspec-clickhouse.rake'
        load 'tasks/rspec-clickhouse-test.rake'
      end
    end
  end
end
