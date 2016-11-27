require 'spec_helper'

describe JSONAPI::Deserializable::Resource, '.configure' do
  it 'overrides global default attribute deserialization scheme' do
    payload = {
      'data' => {
        'type' => 'foo',
        'attributes' => {
          'foo' => 'bar',
          'baz' => 'foo'
        }
      }
    }
    begin
      JSONAPI::Deserializable::Resource.configure do |cfg|
        cfg.default_attribute = proc do |key, value|
          { "custom_#{key}".to_sym => value }
        end
      end
      klass = JSONAPI::Deserializable::Resource
      actual = klass.call(payload)
      expected = { custom_foo: 'bar', custom_baz: 'foo', type: 'foo' }

      expect(actual).to eq(expected)
    ensure
      JSONAPI::Deserializable::Resource.configuration =
        JSONAPI::Deserializable::Resource::Configuration.new
    end
  end

  it 'overrides default attribute deserialization scheme' do
    payload = {
      'data' => {
        'type' => 'foo',
        'attributes' => {
          'foo' => 'bar',
          'baz' => 'foo'
        }
      }
    }
    JSONAPI::Deserializable::Resource[:c1].configure do |cfg|
      cfg.default_attribute = proc do |key, value|
        { "custom_#{key}".to_sym => value }
      end
    end
    klass = JSONAPI::Deserializable::Resource[:c1]
    actual = klass.call(payload)
    expected = { custom_foo: 'bar', custom_baz: 'foo', type: 'foo' }

    expect(actual).to eq(expected)
  end

  it 'overrides the default has_many relationship deserialization scheme' do
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
    JSONAPI::Deserializable::Resource[:c1].configure do |cfg|
      cfg.default_has_many = proc do |name, _value, ids, types|
        { "custom_#{name}_ids".to_sym => ids,
          "custom_#{name}_types".to_sym => types }
      end
    end
    klass = JSONAPI::Deserializable::Resource[:c1]
    actual = klass.call(payload)
    expected = { custom_foo_ids: %w(baz bar), custom_foo_types: %w(bar foo),
                 custom_bar_ids: %w(foo buz), custom_bar_types: %w(baz baz),
                 type: 'foo' }

    expect(actual).to eq(expected)
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
    JSONAPI::Deserializable::Resource[:c1].configure do |cfg|
      cfg.default_has_one = proc do |name, _value, id, type|
        { "custom_#{name}_id".to_sym => id,
          "custom_#{name}_type".to_sym => type }
      end
    end
    klass = JSONAPI::Deserializable::Resource[:c1]
    actual = klass.call(payload)
    expected = { custom_foo_id: 'baz', custom_foo_type: 'bar',
                 custom_bar_id: 'bar', custom_bar_type: 'foo',
                 type: 'foo' }

    expect(actual).to eq(expected)
  end
end
