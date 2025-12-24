# frozen_string_literal: true

require 'click_house/client'
require 'rspec/core'
require 'logger'
require 'ostruct'

require_relative 'clickhouse/version'
require_relative 'clickhouse/configuration'
require_relative 'clickhouse/connection'
require_relative 'clickhouse/db'
require_relative 'clickhouse/helpers'
require_relative 'clickhouse/factory'
require_relative 'clickhouse/factory_registry'

module RSpec
  module Clickhouse
    class Error < StandardError; end
    class ConfigurationError < Error; end

    # Factory definition helper
    #
    # @param name [Symbol] factory name
    # @param options [Hash] factory options (must include :table)
    # @yield factory definition block
    # @example
    #   RSpec::Clickhouse.define_factory :user, table: 'users' do
    #     sequence(:id)
    #     name 'John'
    #   end
    def self.define_factory(name, **options, &block)
      FactoryRegistry.define(name, **options, &block)
    end
  end
end
