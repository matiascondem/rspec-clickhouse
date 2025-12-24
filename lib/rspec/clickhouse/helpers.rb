# frozen_string_literal: true

module RSpec
  module Clickhouse
    module Helpers
      # Insert a single row into ClickHouse table
      #
      # @param table [String] table name
      # @param data [Hash] column => value hash
      # @example
      #   insert_into_clickhouse('users', { id: 1, name: 'Alice', active: true })
      def insert_into_clickhouse(table, data)
        columns = data.keys.join(', ')
        values = data.values.map { |v| quote_clickhouse_value(v) }.join(', ')
        query = "INSERT INTO #{table} (#{columns}) VALUES (#{values})"

        RSpec::Clickhouse.execute(query)
      end
      module_function :insert_into_clickhouse

      # Bulk insert multiple rows into ClickHouse table
      #
      # @param table [String] table name
      # @param rows [Array<Hash>] array of column => value hashes
      # @example
      #   bulk_insert_into_clickhouse('users', [
      #     { id: 1, name: 'Alice' },
      #     { id: 2, name: 'Bob' }
      #   ])
      def bulk_insert_into_clickhouse(table, rows)
        return if rows.empty?

        columns = rows.first.keys.join(', ')
        values_clauses = rows.map do |row|
          values = row.values.map { |v| quote_clickhouse_value(v) }.join(', ')
          "(#{values})"
        end.join(', ')

        query = "INSERT INTO #{table} (#{columns}) VALUES #{values_clauses}"
        RSpec::Clickhouse.execute(query)
      end
      module_function :bulk_insert_into_clickhouse

      # Quote a value for ClickHouse SQL
      #
      # Safely quotes values for SQL insertion, handling:
      # - Strings (with proper escaping)
      # - Arrays
      # - Dates/Times
      # - Booleans
      # - nil values
      #
      # @param value [Object] value to quote
      # @return [String] quoted value safe for SQL
      # @example
      #   quote_clickhouse_value("It's a test")  #=> "'It''s a test'"
      #   quote_clickhouse_value([1, 2, 3])      #=> "[1, 2, 3]"
      #   quote_clickhouse_value(true)           #=> "1"
      #   quote_clickhouse_value(nil)            #=> "NULL"
      def quote_clickhouse_value(value)
        case value
        when String
          # Escape single quotes by doubling them (ClickHouse standard)
          "'#{value.gsub("'", "''")}'"
        when Array
          # ClickHouse arrays: ['a', 'b'] or [1, 2]
          elements = value.map { |v| quote_clickhouse_value(v) }.join(', ')
          "[#{elements}]"
        when Date, Time, DateTime
          "'#{value.strftime('%Y-%m-%d %H:%M:%S')}'"
        when TrueClass, FalseClass
          value ? '1' : '0'
        when nil
          'NULL'
        else
          value.to_s
        end
      end
      module_function :quote_clickhouse_value

      # Factory helper methods

      # Create a ClickHouse record using a factory
      #
      # @param factory_name [Symbol] name of the factory
      # @param traits [Array<Symbol>] optional traits to apply
      # @param attributes [Hash] attribute overrides
      # @return [OpenStruct] created record
      # @example
      #   user = create_clickhouse(:user)
      #   admin = create_clickhouse(:user, :admin, name: 'Custom')
      def create_clickhouse(factory_name, *traits, **attributes)
        factory = FactoryRegistry.find(factory_name)
        factory.create(*traits, **attributes)
      end

      # Create multiple ClickHouse records using a factory
      #
      # @param factory_name [Symbol] name of the factory
      # @param count [Integer] number of records to create
      # @param traits [Array<Symbol>] optional traits to apply
      # @param attributes [Hash] attribute overrides
      # @return [Array<OpenStruct>] created records
      # @example
      #   users = create_clickhouse_list(:user, 100)
      #   admins = create_clickhouse_list(:user, 5, :admin)
      def create_clickhouse_list(factory_name, count, *traits, **attributes)
        factory = FactoryRegistry.find(factory_name)
        factory.create_list(count, *traits, **attributes)
      end

      # Build a ClickHouse record using a factory (doesn't insert)
      #
      # @param factory_name [Symbol] name of the factory
      # @param traits [Array<Symbol>] optional traits to apply
      # @param attributes [Hash] attribute overrides
      # @return [Hash] attribute hash
      # @example
      #   attrs = build_clickhouse(:user)
      def build_clickhouse(factory_name, *traits, **attributes)
        factory = FactoryRegistry.find(factory_name)
        factory.build(*traits, **attributes)
      end
    end
  end
end
