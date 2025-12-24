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
    end
  end
end
