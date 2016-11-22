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

  context 'when providing the relationship name' do
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

  context 'when omitting the relationship name' do
    it 'sets the default has_many relationship deserialization scheme' do
      payload = {
        'data' => {
          'type' => 'foo',
          'relationships' => {
            'foo' => {
              'data' => [{ 'type' => 'bar', 'id' => 'baz' },
                         { 'type' => 'foo', 'id' => 'bar' }]
            },
            'bar' => {
              'data' => [{ 'type' => 'baz', 'id' => 'foo' },
                         { 'type' => 'baz', 'id' => 'buz' }]
            }
          }
        }
      }
      klass = Class.new(JSONAPI::Deserializable::Resource) do
        has_many do |name, _value, ids, types|
          field "custom_#{name}_ids".to_sym => ids
          field "custom_#{name}_types".to_sym => types
        end
      end
      actual = klass.call(payload)
      expected = { custom_foo_ids: %w(baz bar), custom_foo_types: %w(bar foo),
                   custom_bar_ids: %w(foo buz), custom_bar_types: %w(baz baz),
                   type: 'foo' }

      expect(actual).to eq(expected)
    end
  end
end
