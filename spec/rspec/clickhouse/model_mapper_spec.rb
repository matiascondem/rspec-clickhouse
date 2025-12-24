# frozen_string_literal: true

RSpec.describe RSpec::Clickhouse::ModelMapper do
  after do
    described_class.clear!
  end

  let(:model_class) { Class.new }
  let(:model_instance) { model_class.new }

  describe ".define" do
    it "stores mapping for model class" do
      block = ->(model) { { id: 1 } }

      described_class.define(model_class, to: 'table_name', &block)

      # Verify it was stored by trying to use it
      allow(RSpec::Clickhouse::Helpers).to receive(:insert_into_clickhouse)

      expect {
        described_class.sync(model_instance)
      }.not_to raise_error
    end

    it "requires a block" do
      expect {
        described_class.define(model_class, to: 'table_name')
      }.to raise_error(ArgumentError, 'Mapping block required')
    end
  end

  describe ".sync" do
    it "raises error when no mapping defined" do
      expect {
        described_class.sync(model_instance)
      }.to raise_error(ArgumentError, /No mapping defined for/)
    end

    it "calls the mapper block with the model" do
      called_with = nil

      described_class.define(model_class, to: 'test_table') do |model|
        called_with = model
        { id: 1 }
      end

      # Mock the helper to avoid needing ClickHouse
      allow(RSpec::Clickhouse::Helpers).to receive(:insert_into_clickhouse)

      described_class.sync(model_instance)

      expect(called_with).to eq(model_instance)
    end

    it "passes mapped attributes to insert helper" do
      described_class.define(model_class, to: 'test_table') do |model|
        { id: 123, name: 'Test' }
      end

      expect(RSpec::Clickhouse::Helpers).to receive(:insert_into_clickhouse)
        .with('test_table', { id: 123, name: 'Test' })

      described_class.sync(model_instance)
    end
  end

  describe ".bulk_sync" do
    it "raises error when no mapping defined" do
      expect {
        described_class.bulk_sync([model_instance])
      }.to raise_error(ArgumentError, /No mapping defined for/)
    end

    it "handles empty array" do
      expect {
        described_class.bulk_sync([])
      }.not_to raise_error
    end

    it "maps all models and bulk inserts" do
      model2 = model_class.new

      described_class.define(model_class, to: 'test_table') do |model|
        { id: model.object_id }
      end

      expect(RSpec::Clickhouse::Helpers).to receive(:bulk_insert_into_clickhouse)
        .with('test_table', [
          { id: model_instance.object_id },
          { id: model2.object_id }
        ])

      described_class.bulk_sync([model_instance, model2])
    end
  end

  describe ".clear!" do
    it "removes all mappings" do
      described_class.define(model_class, to: 'table') { |m| {} }

      described_class.clear!

      expect {
        described_class.sync(model_instance)
      }.to raise_error(ArgumentError, /No mapping defined/)
    end
  end
end
