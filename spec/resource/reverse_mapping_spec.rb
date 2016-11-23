require 'spec_helper'

describe JSONAPI::Deserializable::Resource, '#reverse_mapping' do
  it 'generates reverse mapping for default type' do
    payload = { 'data' => { 'type' => 'foo' } }
    klass = JSONAPI::Deserializable::Resource
    actual = klass.new(payload).reverse_mapping
    expected = { type: '/data/type' }

    expect(actual).to eq(expected)
  end

  it 'generates reverse mapping for overriden type' do
    payload = { 'data' => { 'type' => 'foo' } }
    klass = Class.new(JSONAPI::Deserializable::Resource) do
      type { |t| { custom_type: t } }
    end
    actual = klass.new(payload).reverse_mapping
    expected = { custom_type: '/data/type' }

    expect(actual).to eq(expected)
  end

  it 'generates reverse mapping for default id' do
    payload = { 'data' => { 'type' => 'foo', 'id' => 'bar' } }
    klass = JSONAPI::Deserializable::Resource
    actual = klass.new(payload).reverse_mapping
    expected = { id: '/data/id', type: '/data/type' }

    expect(actual).to eq(expected)
  end

  it 'generates reverse mapping for overriden id' do
    payload = { 'data' => { 'type' => 'foo', 'id' => 'bar' } }
    klass = Class.new(JSONAPI::Deserializable::Resource) do
      id { |i| { custom_id: i } }
    end
    actual = klass.new(payload).reverse_mapping
    expected = { custom_id: '/data/id', type: '/data/type' }

    expect(actual).to eq(expected)
  end

  it 'generates reverse mapping for default attributes' do
    payload = {
      'data' => {
        'type' => 'foo',
        'attributes' => {
          'foo' => 'bar',
          'baz' => 'fiz'
        }
      }
    }
    klass = JSONAPI::Deserializable::Resource
    actual = klass.new(payload).reverse_mapping
    expected = { type: '/data/type',
                 foo: '/data/attributes/foo',
                 baz: '/data/attributes/baz' }

    expect(actual).to eq(expected)
  end

  it 'generates reverse mapping for locally overriden attributes' do
    payload = {
      'data' => {
        'type' => 'foo',
        'attributes' => {
          'foo' => 'bar',
          'baz' => 'fiz'
        }
      }
    }
    klass = Class.new(JSONAPI::Deserializable::Resource) do
      attribute(:foo) { |foo| { custom_foo: foo } }
    end
    actual = klass.new(payload).reverse_mapping
    expected = { type: '/data/type',
                 custom_foo: '/data/attributes/foo',
                 baz: '/data/attributes/baz' }

    expect(actual).to eq(expected)
  end

  it 'generates reverse mapping for globally overriden attributes' do
    payload = {
      'data' => {
        'type' => 'foo',
        'attributes' => {
          'foo' => 'bar',
          'baz' => 'fiz'
        }
      }
    }
    klass = Class.new(JSONAPI::Deserializable::Resource) do
      attribute { |key, value| { "custom_#{key}".to_sym => value } }
      attribute(:foo) { |foo| { other_foo: foo } }
    end
    actual = klass.new(payload).reverse_mapping
    expected = { type: '/data/type',
                 other_foo: '/data/attributes/foo',
                 custom_baz: '/data/attributes/baz' }

    expect(actual).to eq(expected)
  end

  it 'generates reverse mapping for default has_many' do
    payload = {
      'data' => {
        'type' => 'foo',
        'relationships' => {
          'foo' => {
            'data' => nil
          },
          'baz' => {
            'data' => nil
          }
        }
      }
    }
    klass = JSONAPI::Deserializable::Resource
    actual = klass.new(payload).reverse_mapping
    expected = { type: '/data/type',
                 foo_id: '/data/relationships/foo',
                 foo_type: '/data/relationships/foo',
                 baz_id: '/data/relationships/baz',
                 baz_type: '/data/relationships/baz' }

    expect(actual).to eq(expected)
  end

  it 'generates reverse mapping for overriden has_one' do
    payload = {
      'data' => {
        'type' => 'foo',
        'relationships' => {
          'foo' => {
            'data' => nil
          },
          'baz' => {
            'data' => nil
          }
        }
      }
    }
    klass = Class.new(JSONAPI::Deserializable::Resource) do
      has_one do |key, _val, id, type|
        { "custom_#{key}_id".to_sym => id,
          "custom_#{key}_type".to_sym => type }
      end
      has_one(:foo) do |_val, id, type|
        { other_foo_id: id,
          other_foo_type: type }
      end
    end
    actual = klass.new(payload).reverse_mapping
    expected = { type: '/data/type',
                 other_foo_id: '/data/relationships/foo',
                 other_foo_type: '/data/relationships/foo',
                 custom_baz_id: '/data/relationships/baz',
                 custom_baz_type: '/data/relationships/baz' }

    expect(actual).to eq(expected)
  end

  it 'generates reverse mapping for default has_many' do
    payload = {
      'data' => {
        'type' => 'foo',
        'relationships' => {
          'foo' => {
            'data' => []
          },
          'baz' => {
            'data' => []
          }
        }
      }
    }
    klass = JSONAPI::Deserializable::Resource
    actual = klass.new(payload).reverse_mapping
    expected = { type: '/data/type',
                 foo_ids: '/data/relationships/foo',
                 foo_types: '/data/relationships/foo',
                 baz_ids: '/data/relationships/baz',
                 baz_types: '/data/relationships/baz' }

    expect(actual).to eq(expected)
  end

  it 'generates reverse mapping for overriden has_many' do
    payload = {
      'data' => {
        'type' => 'foo',
        'relationships' => {
          'foo' => {
            'data' => []
          },
          'baz' => {
            'data' => []
          }
        }
      }
    }
    klass = Class.new(JSONAPI::Deserializable::Resource) do
      has_many do |key, _val, ids, types|
        { "custom_#{key}_ids".to_sym => ids,
          "custom_#{key}_types".to_sym => types }
      end
      has_many(:foo) do |_val, ids, types|
        { other_foo_ids: ids,
          other_foo_types: types }
      end
    end
    actual = klass.new(payload).reverse_mapping
    expected = { type: '/data/type',
                 other_foo_ids: '/data/relationships/foo',
                 other_foo_types: '/data/relationships/foo',
                 custom_baz_ids: '/data/relationships/baz',
                 custom_baz_types: '/data/relationships/baz' }

    expect(actual).to eq(expected)
  end
end
