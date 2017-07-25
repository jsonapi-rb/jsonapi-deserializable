require 'spec_helper'

describe JSONAPI::Deserializable::Resource, '.has_one' do
  let(:deserializable_foo) do
    Class.new(JSONAPI::Deserializable::Resource) do
      has_one :foo do |rel, id, type|
        Hash[foo_id: id, foo_type: type, foo_rel: rel]
      end
    end
  end

  context 'relationship is not nil' do
    let(:payload) do
      {
        'type' => 'foo',
        'relationships' => {
          'foo' => {
            'data' => { 'type' => 'foo', 'id' => 'bar' }
          }
        }
      }
    end

    it 'creates corresponding fields' do
      actual = deserializable_foo.call(payload)
      expected = { foo_id: 'bar', foo_type: 'foo',
                   foo_rel: payload['relationships']['foo'] }

      expect(actual).to eq(expected)
    end

    it 'defaults to creating #{name}_id and #{name}_type' do
      klass = Class.new(JSONAPI::Deserializable::Resource) do
        has_one
      end
      actual = klass.call(payload)
      expected = { foo_id: 'bar', foo_type: 'foo' }

      expect(actual).to eq(expected)
    end
  end

  context 'relationship value is nil' do
    it 'creates corresponding fields' do
      payload = {
        'type' => 'foo',
        'relationships' => {
          'foo' => {
            'data' => nil
          }
        }
      }

      actual = deserializable_foo.call(payload)
      expected = { foo_id: nil, foo_type: nil,
                   foo_rel: payload['relationships']['foo'] }

      expect(actual).to eq(expected)
    end
  end

  context 'relationship is absent' do
    it 'does not create corresponding fields' do
      payload = {
        'type' => 'foo',
        'relationships' => {}
      }
      actual = deserializable_foo.call(payload)
      expected = {}

      expect(actual).to eq(expected)
    end
  end

  context 'there is no relationships member' do
    it 'does not create corresponding fields' do
      payload = { 'type' => 'foo' }
      actual = deserializable_foo.call(payload)
      expected = {}

      expect(actual).to eq(expected)
    end
  end
end
