require 'jsonapi/deserializable'

describe JSONAPI::Deserializable::Relationship, '#to_h' do
  it 'deserializes has_one relationships' do
    deserializable_klass = Class.new(JSONAPI::Deserializable::Relationship) do
      has_one do |rel|
        field sponsor_id: (rel['data'] && rel['data']['id'])
      end
    end

    payload = {
      'data' => {
        'type' => 'users',
        'id' => '1'
      }
    }

    actual = deserializable_klass.(payload)
    expected = { sponsor_id: '1' }

    expect(actual).to eq(expected)
  end

  it 'deserializes has_many relationships' do
    deserializable_klass = Class.new(JSONAPI::Deserializable::Relationship) do
      has_many do |rel|
        field post_ids: rel['data'].map { |ri| ri['id'] }
      end
    end

    payload = {
      'data' => [
        { 'type' => 'postd', 'id' => '1' },
        { 'type' => 'postd', 'id' => '2' },
        { 'type' => 'postd', 'id' => '3' }
      ]
    }

    actual = deserializable_klass.(payload)
    expected = { post_ids: %w(1 2 3) }

    expect(actual).to eq(expected)
  end
end
