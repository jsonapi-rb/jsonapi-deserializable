require 'spec_helper'

describe JSONAPI::Deserializable::Relationship, '.has_many' do
  let(:deserializable_foo) do
    Class.new(JSONAPI::Deserializable::Relationship) do
      has_many do |rel, ids, types|
        field foo_ids: ids
        field foo_types: types
        field foo_rel: rel
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

    it 'defaults to creating a relationship field' do
      klass = Class.new(JSONAPI::Deserializable::Relationship) do
        has_many
      end
      actual = klass.call(payload)
      expected = { relationship: payload }

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
    it 'does not create corresponding fields' do
      payload = {}
      actual = deserializable_foo.call(payload)
      expected = {}

      expect(actual).to eq(expected)
    end
  end

  context 'relationship is not to-many' do
    it 'does not create corresponding fields' do
      payload = { 'data' => nil }
      actual = deserializable_foo.call(payload)
      expected = {}

      expect(actual).to eq(expected)
    end
  end
end
