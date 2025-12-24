# frozen_string_literal: true

module RSpec
  module Clickhouse
    # Registry for storing factory definitions
    #
    # Provides a centralized place to store and retrieve factory definitions.
    # Used internally by the factory system.
    module FactoryRegistry
      class << self
        # Define a new factory
        #
        # @param name [Symbol] factory name
        # @param options [Hash] factory options (must include :table)
        # @yield factory definition block
        # @raise [ArgumentError] if table is not provided
        # @example
        #   FactoryRegistry.define(:user, table: 'users') do
        #     sequence(:id)
        #     name 'John'
        #   end
        def define(name, **options, &block)
          raise ArgumentError, "table: required" unless options[:table]

          factory = Factory.new(name, table: options[:table])
          factory.instance_eval(&block)

          factories[name] = factory
        end

        # Find a factory by name
        #
        # @param name [Symbol] factory name
        # @return [Factory] factory instance
        # @raise [ArgumentError] if factory not found
        def find(name)
          factories[name] || raise(ArgumentError, "Factory not found: #{name}")
        end

        # Clear all factories (useful for testing)
        #
        # @return [void]
        def clear!
          factories.clear
        end

        private

        def factories
          @factories ||= {}
        end
      end
    end
  end
end
