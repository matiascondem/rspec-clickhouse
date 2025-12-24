# frozen_string_literal: true

require 'ostruct'

module RSpec
  module Clickhouse
    # FactoryBot-like DSL for creating ClickHouse test data
    #
    # Provides a clean interface for defining factories with:
    # - Attributes (static or dynamic via blocks)
    # - Sequences for auto-incrementing values
    # - Traits for variations
    # - Callbacks (after_create)
    #
    # @example Define a factory
    #   RSpec::Clickhouse.define_factory :user, table: 'users' do
    #     sequence(:id)
    #     name { "User #{id}" }
    #     email { "user#{id}@example.com" }
    #     created_at { Time.current }
    #
    #     trait :admin do
    #       role { 'admin' }
    #     end
    #   end
    #
    # @example Use the factory
    #   user = create_clickhouse(:user)
    #   admin = create_clickhouse(:user, :admin, name: 'Custom')
    #   users = create_clickhouse_list(:user, 100)
    class Factory
      # Note: Not using attr_reader for :name to avoid shadowing DSL methods
      # Access these via instance variables directly when needed
      attr_reader :table, :attributes, :traits, :sequences, :callbacks

      def initialize(name, table:)
        @factory_name = name
        @table = table
        @attributes = {}
        @traits = {}
        @sequences = {}
        @callbacks = { after_create: [] }
      end

      def factory_name
        @factory_name
      end

      # DSL Methods

      # Define a sequence for auto-incrementing values
      #
      # @param attr_name [Symbol] attribute name
      # @param start [Integer] starting value (defaults to config.sequence_start)
      # @example
      #   sequence(:id)
      #   sequence(:number, start: 1000)
      def sequence(attr_name, start: nil)
        start_value = start || RSpec::Clickhouse.configuration.sequence_start
        seq = Sequence.new(start_value)
        @sequences[attr_name] = seq

        # Define attribute that uses sequence
        # Note: Using Proc instead of lambda to be lenient with arity when called with instance_eval
        @attributes[attr_name] = Proc.new { seq.next }
      end

      # Define a trait (variation of the factory)
      #
      # @param trait_name [Symbol] trait name
      # @example
      #   trait :admin do
      #     role { 'admin' }
      #   end
      def trait(trait_name, &block)
        trait_factory = Factory.new("#{@factory_name}_#{trait_name}", table: @table)
        trait_factory.instance_eval(&block)
        @traits[trait_name] = trait_factory
      end

      # Define an after_create callback
      #
      # @example
      #   after_create do |attributes|
      #     puts "Created user with id: #{attributes[:id]}"
      #   end
      def after_create(&block)
        @callbacks[:after_create] << block
      end

      # Dynamic attribute definition via method_missing
      def method_missing(method_name, *args, &block)
        if block_given?
          @attributes[method_name] = block
        elsif args.length == 1
          @attributes[method_name] = args.first
        elsif args.empty?
          # Getter - return the attribute value if it exists
          @attributes[method_name]
        else
          super
        end
      end

      def respond_to_missing?(method_name, include_private = false)
        true
      end

      # Build attributes hash (doesn't insert into ClickHouse)
      #
      # @param trait_names [Array<Symbol>] traits to apply
      # @param overrides [Hash] attribute overrides
      # @return [Hash] built attributes
      def build(*trait_names, **overrides)
        attrs = {}

        # Apply factory defaults
        config_defaults = RSpec::Clickhouse.configuration.factory_defaults
        attrs.merge!(evaluate_attributes(config_defaults))

        # Apply base attributes
        attrs.merge!(evaluate_attributes(@attributes))

        # Apply traits
        trait_names.each do |trait_name|
          trait = @traits[trait_name]
          raise ArgumentError, "Unknown trait: #{trait_name}" unless trait

          attrs.merge!(evaluate_attributes(trait.attributes))
        end

        # Apply overrides
        attrs.merge!(overrides)

        attrs
      end

      # Build and insert into ClickHouse
      #
      # @param trait_names [Array<Symbol>] traits to apply
      # @param overrides [Hash] attribute overrides
      # @return [OpenStruct] created record
      def create(*trait_names, **overrides)
        attrs = build(*trait_names, **overrides)

        # Insert into ClickHouse
        RSpec::Clickhouse::Helpers.insert_into_clickhouse(@table, attrs)

        # Run callbacks
        @callbacks[:after_create].each { |callback| callback.call(attrs) }

        # Return OpenStruct for easy access
        OpenStruct.new(attrs)
      end

      # Build multiple and bulk insert into ClickHouse
      #
      # @param count [Integer] number of records to create
      # @param trait_names [Array<Symbol>] traits to apply
      # @param overrides [Hash] attribute overrides
      # @return [Array<OpenStruct>] created records
      def create_list(count, *trait_names, **overrides)
        rows = count.times.map { build(*trait_names, **overrides) }

        # Bulk insert
        RSpec::Clickhouse::Helpers.bulk_insert_into_clickhouse(@table, rows)

        # Return array of OpenStructs
        rows.map { |row| OpenStruct.new(row) }
      end

      private

      def evaluate_attributes(attrs)
        attrs.transform_values do |value|
          case value
          when Proc
            # Use instance_exec to evaluate procs in the context of the factory
            instance_exec(&value)
          else
            value
          end
        end
      end

      # Internal sequence class
      class Sequence
        def initialize(start)
          @current = start - 1
        end

        def next
          @current += 1
        end
      end
    end
  end
end
