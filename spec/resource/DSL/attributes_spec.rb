require 'spec_helper'

describe JSONAPI::Deserializable::Resource, '.attributes' do
  context 'when no block is specified' do
    context 'when no keys are specified' do
      it 'defaults to creating fields with same name' do
        payload = {
          'type' => 'foo',
          'attributes' => { 'foo' => 'bar', 'baz' => 'foo' }
        }
        klass = Class.new(JSONAPI::Deserializable::Resource) do
          attributes
        end
        actual = klass.call(payload)
        expected = { foo: 'bar', baz: 'foo' }

        expect(actual).to eq(expected)
      end
    end

    context 'when keys are specified' do
      it 'creates fields with same name for whitelisted attributes' do
        payload = {
          'type' => 'foo',
          'attributes' => { 'foo' => 'bar', 'baz' => 'foo', 'bar' => 'foo' }
        }
        klass = Class.new(JSONAPI::Deserializable::Resource) do
          attributes :foo, :baz
        end
        actual = klass.call(payload)
        expected = { foo: 'bar', baz: 'foo' }

        expect(actual).to eq(expected)
      end
    end
  end

  context 'when a block is specified' do
    context 'when no keys are specified' do
      it 'defaults to creating fields with same name' do
        payload = {
          'type' => 'foo',
          'attributes' => { 'foo' => 'bar', 'baz' => 'foo' }
        }
        klass = Class.new(JSONAPI::Deserializable::Resource) do
          attributes do |val, key|
            Hash["#{key}_attr".to_sym => val]
          end
        end
        actual = klass.call(payload)
        expected = { foo_attr: 'bar', baz_attr: 'foo' }

        expect(actual).to eq(expected)
      end
    end

    context 'when keys are specified' do
      it 'creates customized fields for whitelisted attributes' do
        payload = {
          'type' => 'foo',
          'attributes' => { 'foo' => 'bar', 'baz' => 'foo', 'bar' => 'foo' }
        }
        klass = Class.new(JSONAPI::Deserializable::Resource) do
          attributes(:foo, :baz) do |val, key|
            Hash["#{key}_attr".to_sym => val]
          end
        end
        actual = klass.call(payload)
        expected = { foo_attr: 'bar', baz_attr: 'foo' }

        expect(actual).to eq(expected)
      end
    end
  end
end
