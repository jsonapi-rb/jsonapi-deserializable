require 'spec_helper'

describe JSONAPI::Deserializable::Resource, '.has_many' do
  let(:deserializable_foo) do
    Class.new(JSONAPI::Deserializable::Resource) do
      has_many :foo do |rel, ids, types|
        field foo_ids: ids
        field foo_types: types
        field foo_rel: rel
      end
    end
  end

  context 'relationship is not empty' do
    let(:payload) do
      {
        'data' => {
          'type' => 'foo',
          'relationships' => {
            'foo' => {
              'data' => [
                { 'type' => 'foo', 'id' => 'bar' },
                { 'type' => 'foo', 'id' => 'baz' }
              ]
            }
          }
        }
      }
    end

    it 'creates corresponding fields' do
      actual = deserializable_foo.call(payload)
      expected = { foo_ids: %w(bar baz), foo_types: %w(foo foo),
                   foo_rel: payload['data']['relationships']['foo'],
                   type: 'foo' }

      expect(actual).to eq(expected)
    end

    it 'defaults to creating a #{name}_ids and #{name}_types fields' do
      klass = Class.new(JSONAPI::Deserializable::Resource)
      actual = klass.call(payload)
      expected = { foo_ids: %w(bar baz), foo_types: %w(foo foo), type: 'foo' }

      expect(actual).to eq(expected)
    end
  end

  context 'relationship is empty' do
    it 'creates corresponding fields' do
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
      expected = { foo_ids: [], foo_types: [],
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
end
