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

  subject(:document) { JSONAPI::Deserializable::Document.new(payload) }

  it 'works' do
    i = 0
    primary, included = document.process do |res|
      i += 1

      OpenStruct.new(id: i, type: document.resource(res)['type'])
    end

    expect(primary.type).to eq('users')
    expect(included.values.map { |r| r.type })
      .to eq(['addresses', 'posts'])
  end

  context 'when specifying custom directions on edges' do
    let(:payload) do
      {
        'data' => {
          'type' => 'posts',
          'attributes' => { 'title' => 'foo', 'content' => 'bar' },
          'relationships' => {
            'tags' => {
              'data' => [{ 'pointer' => '/included/0' },
                         { 'pointer' => '/included/1' }]
            }
          }
        },
        'included' => [
          {
            'type' => 'tags',
            'attributes' => { 'name' => 'fresh' }
          },
          {
            'type' => 'tags',
            'attributes' => { 'name' => 'mad fresh' }
          }
        ]
      }
    end
    let(:edges_directions) do
      {
        posts: {
          tags: :backward
        }
      }
    end

    it 'works' do
      i = 0
      primary, included = document.process(edges_directions) do |res|
        i += 1

        res = document.resource(res)
        OpenStruct.new(id: i, type: res['type'])
      end

      expect(primary.type).to eq('posts')
      expect(included.values.map { |r| r.type })
        .to eq(['tags', 'tags'])
    end
  end
end
