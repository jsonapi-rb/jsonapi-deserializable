require 'spec_helper'

describe JSONAPI::Deserializable::Resource, '.type' do
  it 'creates corresponding field' do
    payload = { 'type' => 'foo' }
    klass = Class.new(JSONAPI::Deserializable::Resource) do
      type { |t| Hash[type: t] }
    end
    actual = klass.call(payload)
    expected = { type: 'foo' }

    expect(actual).to eq(expected)
  end

  it 'defaults to creating a type field' do
    payload = { 'type' => 'foo' }
    klass = Class.new(JSONAPI::Deserializable::Resource) do
      type
    end
    actual = klass.call(payload)
    expected = { type: 'foo' }

    expect(actual).to eq(expected)
  end
end
