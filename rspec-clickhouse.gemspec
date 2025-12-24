# frozen_string_literal: true

require_relative "lib/rspec/clickhouse/version"

Gem::Specification.new do |spec|
  spec.name          = "rspec-clickhouse"
  spec.version       = RSpec::Clickhouse::VERSION
  spec.authors       = ["Matias Conde"]
  spec.email         = ["matiascondemartinez1997@gmail.com"]

  spec.summary       = "Testing framework for ClickHouse in Rails/RSpec applications"
  spec.description   = "Provides connection management, schema loading, test database " \
                       "support, and RSpec integration for ClickHouse testing"
  spec.homepage      = "https://github.com/matiascondem/rspec-clickhouse"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir[
    "lib/**/*",
    "LICENSE",
    "README.md",
    "CHANGELOG.md"
  ]
  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "click_house-client", "~> 0.8"
  spec.add_dependency "rails", ">= 6.0"
  spec.add_dependency "rspec-core", ">= 3.0"

  # Development dependencies
  spec.add_development_dependency "rspec", "~> 3.12"
end
