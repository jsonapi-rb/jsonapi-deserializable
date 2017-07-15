require 'spec_helper'

describe JSONAPI::Deserializable::Resource, '.id' do
  it 'creates corresponding field if id is present' do
    payload = { 'type' => 'foo', 'id' => 'bar' }
    klass = Class.new(JSONAPI::Deserializable::Resource) do
      id { |i| Hash[id: i] }
    end
    actual = klass.call(payload)
    expected = { id: 'bar' }

    expect(actual).to eq(expected)
  end

  it 'does not create corresponding field if id is absent' do
    payload = { 'type' => 'foo' }
    klass = Class.new(JSONAPI::Deserializable::Resource) do
      id { |i| Hash[id: i] }
    end
    actual = klass.call(payload)
    expected = {}

    expect(actual).to eq(expected)
  end

  it 'defaults to creating an id field' do
    payload = { 'type' => 'foo', 'id' => 'bar' }
    klass = Class.new(JSONAPI::Deserializable::Resource) do
      id
    end
    actual = klass.call(payload)
    expected = { id: 'bar' }

    expect(actual).to eq(expected)
  end
end
