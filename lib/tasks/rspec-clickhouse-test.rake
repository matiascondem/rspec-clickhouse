# frozen_string_literal: true

namespace :clickhouse do
  namespace :test do
    # Shared task to load the spec/support/clickhouse.rb configuration if it exists
    task :load_config do
      # Try to load the configuration from the conventional location
      config_path = Rails.root.join('spec/support/clickhouse.rb')
      require config_path if config_path.exist?
    end

    desc 'Prepare ClickHouse test databases'
    task prepare: %i[environment load_config] do
      unless RSpec::Clickhouse::TestHelper.available?
        puts '✗ ClickHouse is not available!'
        exit 1
      end

      RSpec::Clickhouse::TestDatabaseManager.prepare_test_database
      puts '✓ ClickHouse test databases prepared'
    rescue StandardError => e
      puts "✗ Error: #{e.message}"
      puts e.backtrace.first(10).join("\n") if ENV['DEBUG']
      exit 1
    end

    desc 'Drop ClickHouse test databases'
    task drop: %i[environment load_config] do
      RSpec::Clickhouse::TestDatabaseManager.drop_test_database
      puts '✓ ClickHouse test databases dropped'
    rescue StandardError => e
      puts "✗ Error: #{e.message}"
      puts e.backtrace.first(10).join("\n") if ENV['DEBUG']
      exit 1
    end

    desc 'Reset ClickHouse test databases'
    task reset: :environment do
      Rake::Task['clickhouse:test:drop'].invoke
      Rake::Task['clickhouse:test:prepare'].invoke
    end
  end
end
