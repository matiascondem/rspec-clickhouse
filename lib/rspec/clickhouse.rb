# frozen_string_literal: true

require 'click_house/client'
require 'rspec/core'
require 'logger'

require_relative 'clickhouse/version'
require_relative 'clickhouse/configuration'
require_relative 'clickhouse/connection'
require_relative 'clickhouse/db'
require_relative 'clickhouse/helpers'

module RSpec
  module Clickhouse
    class Error < StandardError; end
    class ConfigurationError < Error; end
  end
end
