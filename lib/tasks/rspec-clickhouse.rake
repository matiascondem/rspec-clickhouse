# frozen_string_literal: true

namespace :clickhouse do
  namespace :schema do
    desc 'Load ClickHouse schema'
    task load: :environment do
      RSpec::Clickhouse::SchemaManager.load_schema
      puts '✓ ClickHouse schema loaded successfully'
    rescue StandardError => e
      puts "✗ Error: #{e.message}"
      exit 1
    end

    desc 'Drop ClickHouse schema'
    task drop: :environment do
      RSpec::Clickhouse::SchemaManager.drop_schema
      puts '✓ ClickHouse schema dropped successfully'
    rescue StandardError => e
      puts "✗ Error: #{e.message}"
      exit 1
    end

    desc 'Reset ClickHouse schema (drop and load)'
    task reset: :environment do
      Rake::Task['clickhouse:schema:drop'].invoke
      Rake::Task['clickhouse:schema:load'].invoke
    end
  end

  desc 'Check ClickHouse connection'
  task ping: :environment do
    if RSpec::Clickhouse.ping
      config = RSpec::Clickhouse.configuration
      puts "✓ ClickHouse available at #{config.clickhouse_url}"
      puts "  Database: #{RSpec::Clickhouse.database_name}"
    else
      puts '✗ ClickHouse not available'
      exit 1
    end
  end
end
