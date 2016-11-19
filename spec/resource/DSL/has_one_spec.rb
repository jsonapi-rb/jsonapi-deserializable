require 'spec_helper'

describe JSONAPI::Deserializable::Resource, '.has_one' do
  let(:deserializable_foo) do
    Class.new(JSONAPI::Deserializable::Resource) do
      has_one :foo do |rel, id, type|
        field foo_id: id
        field foo_type: type
        field foo_rel: rel
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
                   foo_rel: payload['data']['relationships']['foo'] }

      expect(actual).to eq(expected)
    end

    it 'defaults to creating a field of the same name' do
      klass = Class.new(JSONAPI::Deserializable::Resource) do
        has_one :foo
      end
      actual = klass.call(payload)
      expected = { foo: payload['data']['relationships']['foo'] }

      expect(actual).to eq(expected)
    end
  end

  context 'relationship is nil' do
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
                   foo_rel: payload['data']['relationships']['foo'] }

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
      expected = {}

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
      expected = {}

      expect(actual).to eq(expected)
    end
  end

  context 'relationship is not to-one' do
    it 'does not create corresponding fields' do
      payload = {
        'data' => {
          'type' => 'foo',
          'relationships' => {
            'foo' => {
              'data' => []
            }
          }
        }
      }
      actual = deserializable_foo.call(payload)
      expected = {}

      expect(actual).to eq(expected)
    end
  end
end
