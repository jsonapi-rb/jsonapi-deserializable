require 'spec_helper'

describe JSONAPI::Deserializable::Relationship, '.has_one' do
  let(:deserializable_foo) do
    Class.new(JSONAPI::Deserializable::Relationship) do
      has_one do |rel, id, type|
        { foo_id: id, foo_type: type, foo_rel: rel }
      end
    end
  end

  context 'relationship is not nil' do
    let(:payload) do
      { 'data' => { 'type' => 'foo', 'id' => 'bar' } }
    end

    it 'creates corresponding fields' do
      actual = deserializable_foo.call(payload)
      expected = { foo_id: 'bar', foo_type: 'foo', foo_rel: payload }

      expect(actual).to eq(expected)
    end

    it 'defaults to creating id and type fields' do
      klass = Class.new(JSONAPI::Deserializable::Relationship)
      actual = klass.call(payload)
      expected = { id: 'bar', type: 'foo' }

      expect(actual).to eq(expected)
    end
  end

  context 'relationship is nil' do
    it 'creates corresponding fields' do
      payload = { 'data' => nil }
      actual = deserializable_foo.call(payload)
      expected = { foo_id: nil, foo_type: nil, foo_rel: payload }

      expect(actual).to eq(expected)
    end
  end

  context 'data is absent' do
    it 'raises InvalidDocument' do
      payload = {}

      expect { deserializable_foo.call(payload) }.to raise_error
    end
  end

  context 'relationship is not to-one' do
    it 'falls back to default has_many deserialization scheme ' do
      payload = { 'data' => [] }
      actual = deserializable_foo.call(payload)
      expected = { ids: [], types: [] }

      expect(actual).to eq(expected)
    end
  end
end
