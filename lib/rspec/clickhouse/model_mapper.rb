# frozen_string_literal: true

module RSpec
  module Clickhouse
    module ModelMapper
      class << self
        def define(model_class, to:, &block)
          raise ArgumentError, "Mapping block required" unless block_given?

          mappings[model_class] = { table: to, mapper: block }
        end

        def sync(model)
          mapping = mappings[model.class]
          raise ArgumentError, "No mapping defined for #{model.class}" unless mapping

          attrs = mapping[:mapper].call(model)
          RSpec::Clickhouse::Helpers.insert_into_clickhouse(mapping[:table], attrs)
        end

        def bulk_sync(models)
          return if models.empty?

          model_class = models.first.class
          mapping = mappings[model_class]
          raise ArgumentError, "No mapping defined for #{model_class}" unless mapping

          rows = models.map { |model| mapping[:mapper].call(model) }
          RSpec::Clickhouse::Helpers.bulk_insert_into_clickhouse(mapping[:table], rows)
        end

        def clear!
          mappings.clear
        end

        private

        def mappings
          @mappings ||= {}
        end
      end
    end
  end
end
