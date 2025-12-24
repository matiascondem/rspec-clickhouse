# frozen_string_literal: true

RSpec.describe RSpec::Clickhouse::FactoryRegistry do
  after do
    described_class.clear!
  end

  describe ".define" do
    it "creates and stores a factory" do
      described_class.define(:user, table: 'users') do
        sequence(:id)
        name 'John'
      end

      factory = described_class.find(:user)
      expect(factory).to be_a(RSpec::Clickhouse::Factory)
      expect(factory.table).to eq('users')
    end

    it "requires table option" do
      expect {
        described_class.define(:user) do
          name 'John'
        end
      }.to raise_error(ArgumentError, 'table: required')
    end

    it "evaluates the block in factory context" do
      described_class.define(:user, table: 'users') do
        sequence(:id)
        name 'John'
      end

      factory = described_class.find(:user)
      attrs = factory.build

      expect(attrs[:id]).to eq(1)
      expect(attrs[:name]).to eq('John')
    end
  end

  describe ".find" do
    it "returns the factory by name" do
      described_class.define(:user, table: 'users') {}

      factory = described_class.find(:user)
      expect(factory.factory_name).to eq(:user)
    end

    it "raises error when factory not found" do
      expect {
        described_class.find(:nonexistent)
      }.to raise_error(ArgumentError, 'Factory not found: nonexistent')
    end
  end

  describe ".clear!" do
    it "removes all factories" do
      described_class.define(:user, table: 'users') {}
      described_class.define(:post, table: 'posts') {}

      described_class.clear!

      expect {
        described_class.find(:user)
      }.to raise_error(ArgumentError, 'Factory not found: user')

      expect {
        described_class.find(:post)
      }.to raise_error(ArgumentError, 'Factory not found: post')
    end
  end
end
