# frozen_string_literal: true

require 'bundler/setup'
require 'net/http'

# Load gem without auto-loading RSpec integration
require 'rspec/clickhouse'

# Configure ClickHouse client BEFORE configuring our gem
ClickHouse::Client.configure do |client_config|
  client_config.http_post_proc = lambda do |url, headers, body|
    uri = URI.parse(url)

    uri.query = [uri.query, URI.encode_www_form(body.except('query'))].compact.join('&') unless body.is_a?(IO)

    request = Net::HTTP::Post.new(uri)

    headers.each do |header, value|
      request[header] = value
    end

    request['Content-type'] = 'application/x-www-form-urlencoded'

    if body.is_a?(IO)
      request.body_stream = body
    else
      request.body = body['query']
    end

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
      http.request(request)
    end

    ClickHouse::Client::Response.new(response.body, response.code.to_i, response.each_header.to_h)
  end

  client_config.register_database(
    :main,
    database: 'rspec_clickhouse_test',
    url: ENV.fetch('CLICKHOUSE_URL', 'http://localhost:8123'),
    username: ENV.fetch('CLICKHOUSE_USERNAME', 'default'),
    password: ENV.fetch('CLICKHOUSE_PASSWORD', ''),
    variables: { mutations_sync: 1 }
  )
end

# Configure for integration tests
RSpec::Clickhouse.configure do |config|
  config.clickhouse_url = ENV.fetch('CLICKHOUSE_URL', 'http://localhost:8123')
  config.clickhouse_username = ENV.fetch('CLICKHOUSE_USERNAME', 'default')
  config.clickhouse_password = ENV.fetch('CLICKHOUSE_PASSWORD', '')
  config.database_name = 'rspec_clickhouse_test'
  config.test_database_prefix = 'rspec_clickhouse_test'
  config.schema_root = File.expand_path('fixtures/clickhouse', __dir__)
  config.schema_load_order = %w[functions tables views]
  config.parallel_test_databases = ['']
  config.truncate_excluded_tables = []
  config.auto_truncate_metadata = :clickhouse
end

RSpec.configure do |config|
  config.example_status_persistence_file_path = ".rspec_status"
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Set up test database before suite
  config.before(:suite) do
    # Drop and recreate test database
    admin_config = ClickHouse::Client::Configuration.new
    admin_config.http_post_proc = ClickHouse::Client.configuration.http_post_proc
    password = RSpec::Clickhouse.configuration.clickhouse_password
    admin_config.register_database(
      :main,
      database: 'default',
      url: RSpec::Clickhouse.configuration.clickhouse_url,
      username: RSpec::Clickhouse.configuration.clickhouse_username,
      password: password.to_s.empty? ? '' : password
    )
    admin_conn = RSpec::Clickhouse::Connection.new(:main, admin_config)

    # Drop if exists
    admin_conn.execute('DROP DATABASE IF EXISTS rspec_clickhouse_test')

    # Create fresh
    admin_conn.execute('CREATE DATABASE rspec_clickhouse_test')

    # Load schema
    RSpec::Clickhouse::SchemaManager.load_schema
  end

  # Clean up after suite
  config.after(:suite) do
    admin_config = ClickHouse::Client::Configuration.new
    admin_config.http_post_proc = ClickHouse::Client.configuration.http_post_proc
    password = RSpec::Clickhouse.configuration.clickhouse_password
    admin_config.register_database(
      :main,
      database: 'default',
      url: RSpec::Clickhouse.configuration.clickhouse_url,
      username: RSpec::Clickhouse.configuration.clickhouse_username,
      password: password.to_s.empty? ? '' : password
    )
    admin_conn = RSpec::Clickhouse::Connection.new(:main, admin_config)
    admin_conn.execute('DROP DATABASE IF EXISTS rspec_clickhouse_test')
  end

  # Include helpers for integration tests
  config.include RSpec::Clickhouse::Helpers, type: :integration
end
