require 'spec_helper'

describe JSONAPI::Deserializable::Relationship, '.has_many' do
  let(:deserializable_foo) do
    Class.new(JSONAPI::Deserializable::Relationship) do
      has_many do |rel, ids, types|
        { foo_ids: ids, foo_types: types, foo_rel: rel }
      end
    end
  end

  context 'relationship is not empty' do
    let(:payload) do
      {
        'data' => [
          { 'type' => 'foo', 'id' => 'bar' },
          { 'type' => 'foo', 'id' => 'baz' }
        ]
      }
    end

    it 'creates corresponding fields' do
      actual = deserializable_foo.call(payload)
      expected = { foo_ids: %w(bar baz), foo_types: %w(foo foo),
                   foo_rel: payload }

      expect(actual).to eq(expected)
    end

    it 'defaults to creating ids and types fields' do
      klass = Class.new(JSONAPI::Deserializable::Relationship) do
        has_many
      end
      actual = klass.call(payload)
      expected = { ids: %w(bar baz), types: %w(foo foo) }

      expect(actual).to eq(expected)
    end
  end

  context 'relationship is empty' do
    it 'creates corresponding fields' do
      payload = { 'data' => [] }
      actual = deserializable_foo.call(payload)
      expected = { foo_ids: [], foo_types: [], foo_rel: payload }

      expect(actual).to eq(expected)
    end
  end

  context 'data is absent' do
    it 'creates an empty hash' do
      payload = {}
      actual = deserializable_foo.call(payload)
      expected = {}

      expect(actual).to eq(expected)
    end
  end

  context 'relationship is not to-many' do
    it 'does not deserialize relationship' do
      payload = { 'data' => nil }
      actual = deserializable_foo.call(payload)
      expected = {}

      expect(actual).to eq(expected)
    end
  end
end
