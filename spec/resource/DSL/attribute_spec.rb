require 'spec_helper'

describe JSONAPI::Deserializable::Resource, '.attribute' do
  it 'creates corresponding field if attribute is present' do
    payload = {
      'data' => {
        'type' => 'foo',
        'attributes' => { 'foo' => 'bar' }
      }
    }
    klass = Class.new(JSONAPI::Deserializable::Resource) do
      attribute(:foo) { |foo| Hash[foo: foo] }
    end
    actual = klass.call(payload)
    expected = { foo: 'bar', type: 'foo' }

    expect(actual).to eq(expected)
  end

  it 'does not create corresponding field if attribute is absent' do
    payload = { 'data' => { 'type' => 'foo', 'attributes' => {} } }
    klass = Class.new(JSONAPI::Deserializable::Resource) do
      attribute(:foo) { |foo| Hash[foo: foo] }
    end
    actual = klass.call(payload)
    expected = { type: 'foo' }

    expect(actual).to eq(expected)
  end

  it 'does not create corresponding field if no attribute specified' do
    payload = { 'data' => { 'type' => 'foo' } }
    klass = Class.new(JSONAPI::Deserializable::Resource) do
      attribute(:foo) { |foo| Hash[foo: foo] }
    end
    actual = klass.call(payload)
    expected = { type: 'foo' }

    expect(actual).to eq(expected)
  end

  it 'defaults to creating a field with same name' do
    payload = {
      'data' => {
        'type' => 'foo',
        'attributes' => { 'foo' => 'bar' }
      }
    }
    klass = Class.new(JSONAPI::Deserializable::Resource)
    actual = klass.call(payload)
    expected = { foo: 'bar', type: 'foo' }

    expect(actual).to eq(expected)
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
    klass = Class.new(JSONAPI::Deserializable::Resource) do
      def deserialize_attribute(name, value)
        { "custom_#{name}".to_sym => value }
      end
    end
    actual = klass.call(payload)
    expected = { custom_foo: 'bar', custom_baz: 'foo', type: 'foo' }

    expect(actual).to eq(expected)
  end
end
