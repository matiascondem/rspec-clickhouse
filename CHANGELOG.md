# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2024-12-24

### Added
- Initial release
- Connection management with thread-safe pooling
- Configuration DSL for flexible setup
- Schema management system with dependency ordering
- Parallel test database support
- RSpec integration with metadata-driven test isolation
- Factory system with FactoryBot-like DSL
  - Sequences for auto-incrementing values
  - Traits for factory variations
  - Bulk creation support
- Model mapper for syncing ActiveRecord to ClickHouse
- Helper methods for inserting and querying data
- Rake tasks for schema and test database management
- Rails generator for easy installation
- Complete test suite (72 examples)
  - 45 unit tests
  - 27 integration tests
- Comprehensive documentation

[Unreleased]: https://github.com/matiascondem/rspec-clickhouse/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/matiascondem/rspec-clickhouse/releases/tag/v0.1.0
