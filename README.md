# rspec-clickhouse

[![CI](https://github.com/matiascondem/rspec-clickhouse/actions/workflows/ci.yml/badge.svg)](https://github.com/matiascondem/rspec-clickhouse/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/rspec-clickhouse.svg)](https://badge.fury.io/rb/rspec-clickhouse)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Testing framework for ClickHouse in Rails/RSpec applications.

## Features

- **Connection Management**: Thread-safe connection pooling
- **Schema Management**: Load SQL schemas with dependency ordering
- **Test Infrastructure**: Parallel test database support with automatic cleanup
- **RSpec Integration**: Metadata-driven test isolation
- **Factory System**: FactoryBot-like DSL for creating ClickHouse test data
- **Model Mapping**: Sync ActiveRecord models to ClickHouse
- **Rails Integration**: Automatic setup via Railtie

## Installation

Add to your Gemfile:

```ruby
gem 'rspec-clickhouse'
```

Then run:

```bash
bundle install
rails generate rspec:clickhouse:install
```

## Quick Start

### 1. Configure ClickHouse

The generator creates `config/initializers/clickhouse.rb`:

```ruby
RSpec::Clickhouse.configure do |config|
  config.clickhouse_url = ENV.fetch('CLICKHOUSE_URL', 'http://localhost:8123')
  config.database_name = 'myapp'
  config.test_database_prefix = 'myapp_test'
  config.schema_root = Rails.root.join('clickhouse')
end
```

### 2. Organize Your Schema

Create your ClickHouse schema files:

```
clickhouse/
├── functions/
│   └── my_function.sql
├── tables/
│   └── my_table.sql
└── views/
    └── my_view.sql
```

### 3. Prepare Test Database

```bash
bundle exec rake clickhouse:test:prepare
```

### 4. Write Tests

```ruby
RSpec.describe MyService, clickhouse: true do
  it 'creates facts' do
    # Data is automatically cleaned up before each test
    insert_into_clickhouse('my_table', {
      id: 1,
      name: 'Test',
      created_at: Time.current
    })

    result = RSpec::Clickhouse.select('SELECT * FROM my_table')
    expect(result.size).to eq(1)
  end
end
```

## Factory System

Define factories for ClickHouse tables in `spec/support/clickhouse_factories.rb`:

```ruby
RSpec::Clickhouse.define_factory :user_fact, table: 'user_facts' do
  sequence(:id)
  name { "User #{id}" }
  email { "user#{id}@example.com" }
  created_at { Time.current }

  trait :admin do
    role { 'admin' }
  end
end
```

Use in specs:

```ruby
# Create single record
user = create_clickhouse(:user_fact, name: 'Custom')

# Create with trait
admin = create_clickhouse(:user_fact, :admin)

# Create multiple records
users = create_clickhouse_list(:user_fact, 100)
```

## Model Mapping

Sync ActiveRecord models to ClickHouse:

```ruby
RSpec::Clickhouse.map_model User, to: :user_facts do |user|
  {
    id: user.id,
    name: user.name,
    email: user.email,
    created_at: user.created_at
  }
end

# In specs
user = create(:user)
sync_to_clickhouse(user)

# Or bulk sync
users = create_list(:user, 100)
bulk_sync_to_clickhouse(users)
```

## Rake Tasks

```bash
# Schema management
rake clickhouse:schema:load
rake clickhouse:schema:drop
rake clickhouse:schema:reset

# Test database management
rake clickhouse:test:prepare
rake clickhouse:test:drop
rake clickhouse:test:reset

# Check connection
rake clickhouse:ping
```

## Development

### Running Tests

The gem has comprehensive test coverage (72 specs):

**Unit tests only** (no ClickHouse required):
```bash
bundle install
bundle exec rspec spec/rspec/
# 45 examples, 0 failures
```

**Integration tests** (requires ClickHouse):
```bash
# Make sure ClickHouse is running on localhost:8123
bundle exec rspec spec/integration/
# 27 examples, 0 failures
```

**All tests**:
```bash
bundle exec rspec
# 72 examples, 0 failures
# - 45 unit tests
# - 27 integration tests
```

## Requirements

- Ruby 2.7+
- Rails 6.0+
- RSpec 3.0+
- ClickHouse 20.0+ (for integration tests and actual usage)

## License

MIT - See [LICENSE](LICENSE) for details.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/matiascondem/rspec-clickhouse.

## Author

Matias Conde ([@matiascondem](https://github.com/matiascondem))
