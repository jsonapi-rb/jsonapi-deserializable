require 'spec_helper'

describe JSONAPI::Deserializable::Resource, '.key_format' do
  subject { klass.call(payload) }

  let(:payload) do
    {
      'type' => 'foo',
      'attributes' => { 'foo' => 'bar', 'foo-bar' => 'baz' },
      'relationships' => {
        'baz' => {
          'data' => nil
        },
        'bar-baz' => {
          'data' => []
        }
      }
    }
  end

  context 'when all fields are whitelisted' do
    context 'when a key formatter is provided as a block' do
      let(:klass) do
        Class.new(JSONAPI::Deserializable::Resource) do
          key_format { |k| k.capitalize }
          attributes
          has_many
          has_one
        end
      end

      it 'formats keys accordingly' do
        is_expected.to eq(Foo: 'bar', 'Foo-bar'.to_sym => 'baz',
                          Baz_id: nil, Baz_type: nil,
                          'Bar-baz_ids'.to_sym => [],
                          'Bar-baz_types'.to_sym => [])
      end
    end

    context 'when a key formatter is provided as a callable' do
      let(:klass) do
        Class.new(JSONAPI::Deserializable::Resource) do
          key_format ->(k) { k.capitalize }
          attributes
          has_many
          has_one
        end
      end

      it 'formats keys accordingly' do
        is_expected.to eq(Foo: 'bar', 'Foo-bar'.to_sym => 'baz',
                          Baz_id: nil, Baz_type: nil,
                          'Bar-baz_ids'.to_sym => [],
                          'Bar-baz_types'.to_sym => [])
      end
    end
  end

  context 'when certain fields are whitelisted' do
    let(:klass) do
      Class.new(JSONAPI::Deserializable::Resource) do
        key_format { |k| k.capitalize }
        attributes :foo
        has_one :baz
      end
    end

    it 'formats keys accordingly' do
      is_expected.to eq(Foo: 'bar',
                        Baz_id: nil, Baz_type: nil)
    end
  end

  context 'when inheriting' do
    let(:klass) do
      superclass = Class.new(JSONAPI::Deserializable::Resource) do
        key_format { |k| k.capitalize }
      end

      Class.new(superclass) do
        attributes
        has_many
        has_one
      end
    end

    it 'formats keys accordingly' do
      is_expected.to eq(Foo: 'bar', 'Foo-bar'.to_sym => 'baz',
                        Baz_id: nil, Baz_type: nil,
                        'Bar-baz_ids'.to_sym => [],
                        'Bar-baz_types'.to_sym => [])
    end
  end
end
