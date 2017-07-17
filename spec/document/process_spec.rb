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
    resources = []
    i = 0
    document.process do |res|
      resources << res
      i += 1

      i
    end

    expect(resources.map { |r| r['type'] })
      .to eq(['addresses', 'posts', 'users'])
  end
end
