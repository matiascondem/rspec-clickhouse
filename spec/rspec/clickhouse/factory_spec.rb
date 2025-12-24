# frozen_string_literal: true

RSpec.describe RSpec::Clickhouse::Factory do
  let(:factory) { described_class.new(:test_fact, table: 'test_table') }

  describe "#initialize" do
    it "sets name and table" do
      expect(factory.factory_name).to eq(:test_fact)
      expect(factory.table).to eq('test_table')
    end
  end

  describe "#sequence" do
    it "creates a sequence attribute" do
      factory.sequence(:id)
      attrs = factory.build

      expect(attrs[:id]).to eq(1)
    end

    it "increments on each call" do
      factory.sequence(:id)

      expect(factory.build[:id]).to eq(1)
      expect(factory.build[:id]).to eq(2)
      expect(factory.build[:id]).to eq(3)
    end

    it "accepts custom start value" do
      factory.sequence(:id, start: 100)

      expect(factory.build[:id]).to eq(100)
      expect(factory.build[:id]).to eq(101)
    end
  end

  describe "#build" do
    it "builds attributes hash" do
      factory.instance_eval do
        name { 'Test' }
        value { 123 }
      end

      attrs = factory.build

      expect(attrs[:name]).to eq('Test')
      expect(attrs[:value]).to eq(123)
    end

    it "evaluates procs" do
      factory.instance_eval do
        created_at { Time.new(2024, 1, 1) }
      end

      attrs = factory.build

      expect(attrs[:created_at]).to eq(Time.new(2024, 1, 1))
    end

    it "accepts overrides" do
      factory.instance_eval do
        name { 'Default' }
      end

      attrs = factory.build(name: 'Custom')

      expect(attrs[:name]).to eq('Custom')
    end
  end

  describe "#trait" do
    it "defines a trait" do
      factory.instance_eval do
        name { 'Base' }

        trait :special do
          name { 'Special' }
        end
      end

      base_attrs = factory.build
      special_attrs = factory.build(:special)

      expect(base_attrs[:name]).to eq('Base')
      expect(special_attrs[:name]).to eq('Special')
    end
  end
end
