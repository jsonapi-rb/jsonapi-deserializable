require 'spec_helper'

describe JSONAPI::Deserializable::Resource, '.attribute' do
  context 'when attribute is present' do
    context 'when a block is specified' do
      it 'creates corresponding field' do
        payload = {
          'type' => 'foo',
          'attributes' => { 'foo' => 'bar' }
        }
        klass = Class.new(JSONAPI::Deserializable::Resource) do
          attribute(:foo) { |foo| Hash[foo: foo] }
        end
        actual = klass.call(payload)
        expected = { foo: 'bar' }

        expect(actual).to eq(expected)
      end
    end

    context 'when no block is specified' do
      it 'defaults to creating a field with same name' do
        payload = {
          'type' => 'foo',
          'attributes' => { 'foo' => 'bar' }
        }
        klass = Class.new(JSONAPI::Deserializable::Resource) do
          attribute(:foo)
        end
        actual = klass.call(payload)
        expected = { foo: 'bar' }

        expect(actual).to eq(expected)
      end
    end
  end

  context 'when attribute is absent' do
    it 'does not create corresponding field if attribute is absent' do
      payload = { 'type' => 'foo', 'attributes' => {} }
      klass = Class.new(JSONAPI::Deserializable::Resource) do
        attribute(:foo) { |foo| Hash[foo: foo] }
      end
      actual = klass.call(payload)
      expected = {}

      expect(actual).to eq(expected)
    end
  end

  context 'when attributes member is absent' do
    it 'does not create corresponding field if no attribute specified' do
      payload = { 'type' => 'foo' }
      klass = Class.new(JSONAPI::Deserializable::Resource) do
        attribute(:foo) { |foo| Hash[foo: foo] }
      end
      actual = klass.call(payload)
      expected = {}

      expect(actual).to eq(expected)
    end
  end
end
