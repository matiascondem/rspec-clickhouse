# frozen_string_literal: true

require 'rspec/clickhouse'

# Auto-setup RSpec integration if RSpec is loaded
if defined?(::RSpec)
  RSpec::Clickhouse::RSpecIntegration.setup!
end
