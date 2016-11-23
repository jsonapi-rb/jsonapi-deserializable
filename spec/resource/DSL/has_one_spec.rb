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
        'data' => {
          'type' => 'foo',
          'relationships' => {
            'foo' => {
              'data' => { 'type' => 'foo', 'id' => 'bar' }
            }
          }
        }
      }
    end

    it 'creates corresponding fields' do
      actual = deserializable_foo.call(payload)
      expected = { foo_id: 'bar', foo_type: 'foo',
                   foo_rel: payload['data']['relationships']['foo'],
                   type: 'foo' }

      expect(actual).to eq(expected)
    end

    it 'defaults to creating #{name}_id and #{name}_type' do
      klass = Class.new(JSONAPI::Deserializable::Resource)
      actual = klass.call(payload)
      expected = { foo_id: 'bar', foo_type: 'foo', type: 'foo' }

      expect(actual).to eq(expected)
    end
  end

  context 'relationship value is nil' do
    it 'creates corresponding fields' do
      payload = {
        'data' => {
          'type' => 'foo',
          'relationships' => {
            'foo' => {
              'data' => nil
            }
          }
        }
      }

      actual = deserializable_foo.call(payload)
      expected = { foo_id: nil, foo_type: nil,
                   foo_rel: payload['data']['relationships']['foo'],
                   type: 'foo' }

      expect(actual).to eq(expected)
    end
  end

  context 'relationship is absent' do
    it 'does not create corresponding fields' do
      payload = {
        'data' => {
          'type' => 'foo',
          'relationships' => {}
        }
      }
      actual = deserializable_foo.call(payload)
      expected = { type: 'foo' }

      expect(actual).to eq(expected)
    end
  end

  context 'there is no relationships member' do
    it 'does not create corresponding fields' do
      payload = {
        'data' => {
          'type' => 'foo'
        }
      }
      actual = deserializable_foo.call(payload)
      expected = { type: 'foo' }

      expect(actual).to eq(expected)
    end
  end

  it 'overrides the default has_one relationship deserialization scheme' do
    payload = {
      'data' => {
        'type' => 'foo',
        'relationships' => {
          'foo' => { 'data' => { 'type' => 'bar', 'id' => 'baz' } },
          'bar' => { 'data' => { 'type' => 'foo', 'id' => 'bar' } }
        }
      }
    }
    klass = Class.new(JSONAPI::Deserializable::Resource) do
      def deserialize_has_one(name, _value, id, type)
        { "custom_#{name}_id".to_sym => id,
          "custom_#{name}_type".to_sym => type }
      end
    end
    actual = klass.call(payload)
    expected = { custom_foo_id: 'baz', custom_foo_type: 'bar',
                 custom_bar_id: 'bar', custom_bar_type: 'foo',
                 type: 'foo' }

    expect(actual).to eq(expected)
  end
end
