require 'spec_helper'

describe JSONAPI::Deserializable::Document, '#validate' do
  let(:payload) do
    {
      'data' => {
        'type' => 'users',
        'attributes' => { 'name' => 'Lucas' },
        'relationships' => {
          'primary_address' => {
            'data' => {
              'pointer' => '/included/0'
            }
          },
          'posts' => {
            'data' => [
              { 'type' => 'posts', 'id' => '1' },
              { 'pointer' => '/included/1' }
            ]
          }
        }
      },
      'included' => [
        {
          'type' => 'addresses',
          'attributes' => { 'street' => 'foo', 'city' => 'Paris' }
        },
        {
          'type' => 'posts',
          'attributes' => { 'title' => 'Sideposting',
                            'content' => 'It\'s easy' }
        }
      ]
    }
  end

  subject { JSONAPI::Deserializable::Document.new(payload) }

  context 'when document is valid' do
    let(:whitelist) do
      {
        one: {
          primary_address: {
            pointers: true,
            types: [:addresses]
          },
        },
        many: {
          posts: {
            pointers: true,
            types: [:posts]
          }
        }
      }
    end

    it 'does not yield' do
      expect { |b| subject.validate(whitelist, &b).not_to yield_control }
    end
  end

  context 'when document contains an unauthorized relationship' do
    let(:whitelist) do
      {
        many: {
          posts: {
            pointers: true,
            types: [:posts]
          }
        }
      }
    end

    it 'yields once' do
      expect { |b| subject.validate(whitelist, &b) }.to yield_control.once
    end
  end

  context 'when document contains an unauthorized type' do
    let(:whitelist) do
      {
        one: {
          primary_address: {
            pointers: true,
            types: [:foo]
          }
        },
        many: {
          posts: {
            pointers: true,
            types: [:posts]
          }
        }
      }
    end

    it 'yields once' do
      expect { |b| subject.validate(whitelist, &b) }.to yield_control.once
    end
  end

  context 'when document contains a relationship with wrong arity' do
    let(:whitelist) do
      {
        one: {
          primary_address: {
            pointers: true,
            types: [:addresses]
          },
          posts: {
            pointers: true,
            types: [:posts]
          }
        }
      }
    end

    it 'yields once' do
      expect { |b| subject.validate(whitelist, &b) }.to yield_control.once
    end
  end

  context 'when document contains a relationship with unauthorized pointers' do
    let(:whitelist) do
      {
        one: {
          primary_address: {
            types: [:addresses]
          }
        },
        many: {
          posts: {
            pointers: true,
            types: [:posts]
          }
        }
      }
    end

    it 'yields once' do
      expect { |b| subject.validate(whitelist, &b) }.to yield_control.once
    end
  end
end
