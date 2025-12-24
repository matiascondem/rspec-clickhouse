# frozen_string_literal: true

namespace :clickhouse do
  namespace :test do
    desc 'Prepare ClickHouse test databases'
    task prepare: :environment do
      unless RSpec::Clickhouse.ping
        puts '✗ ClickHouse is not available!'
        exit 1
      end

      RSpec::Clickhouse::TestDatabaseManager.prepare_test_database
      puts '✓ ClickHouse test databases prepared'
    rescue StandardError => e
      puts "✗ Error: #{e.message}"
      exit 1
    end

    desc 'Drop ClickHouse test databases'
    task drop: :environment do
      RSpec::Clickhouse::TestDatabaseManager.drop_test_database
      puts '✓ ClickHouse test databases dropped'
    rescue StandardError => e
      puts "✗ Error: #{e.message}"
      exit 1
    end

    desc 'Reset ClickHouse test databases'
    task reset: :environment do
      Rake::Task['clickhouse:test:drop'].invoke
      Rake::Task['clickhouse:test:prepare'].invoke
    end
  end
end
