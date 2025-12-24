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
require_relative 'clickhouse/model_mapper'

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

    # Model mapper definition helper
    #
    # @param model_class [Class] ActiveRecord model class
    # @param to [String] target ClickHouse table name
    # @yield mapping block that receives model and returns attributes hash
    # @example
    #   RSpec::Clickhouse.map_model User, to: 'users' do |user|
    #     {
    #       id: user.id,
    #       name: user.name,
    #       email: user.email,
    #       created_at: user.created_at
    #     }
    #   end
    def self.map_model(model_class, to:, &block)
      ModelMapper.define(model_class, to: to, &block)
    end
  end
end
