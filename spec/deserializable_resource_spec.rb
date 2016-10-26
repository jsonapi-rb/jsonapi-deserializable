require 'jsonapi/deserializable'

describe JSONAPI::Deserializable::Resource, '#to_h' do
  before(:all) do
    @payload = {
      'data' => {
        'id' => '1',
        'type' => 'users',
        'attributes' => {
          'name' => 'Name',
          'address' => 'Address'
        },
        'relationships' => {
          'sponsor' => {
            'data' => { 'type' => 'users', 'id' => '1337' }
          },
          'posts' => {
            'data' => [
              { 'type' => 'posts', 'id' => '123' },
              { 'type' => 'posts', 'id' => '234' },
              { 'type' => 'posts', 'id' => '345' }
            ]
          }
        }
      }
    }
  end

  it 'deserializes primary type' do
    deserializable_klass = Class.new(JSONAPI::Deserializable::Resource) do
      type { |type| field type: type }
    end

    actual = deserializable_klass.(@payload)
    expected = { type: 'users' }

    expect(actual).to eq(expected)
  end

  it 'deserializes primary id when present' do
    deserializable_klass = Class.new(JSONAPI::Deserializable::Resource) do
      id { |id| field id: id }
    end

    actual = deserializable_klass.(@payload)
    expected = { id: '1' }

    expect(actual).to eq(expected)
  end

  it 'does not deserialize primary id when absent' do
    deserializable_klass = Class.new(JSONAPI::Deserializable::Resource) do
      id { |id| field id: id }
    end

    payload = {
      'data' => { 'type' => 'users' }
    }
    actual = deserializable_klass.(payload)
    expected = {}

    expect(actual).to eq(expected)
  end

  it 'handles attributes' do
    deserializable_klass = Class.new(JSONAPI::Deserializable::Resource) do
      attribute(:name) { |name| field username: name }
      attribute(:address) { |address| field address: address }
    end

    actual = deserializable_klass.(@payload)
    expected = {
      username: 'Name',
      address: 'Address'
    }

    expect(actual).to eq(expected)
  end

  it 'handles has_one relationships' do
    deserializable_klass = Class.new(JSONAPI::Deserializable::Resource) do
      has_one(:sponsor) { |rel| field sponsor_id: rel['data']['id'] }
    end

    actual = deserializable_klass.(@payload)
    expected = {
      sponsor_id: '1337'
    }

    expect(actual).to eq(expected)
  end

  it 'handles has_many relationships' do
    deserializable_klass = Class.new(JSONAPI::Deserializable::Resource) do
      has_many(:posts) do |rel|
        field post_ids: rel['data'].map { |ri| ri['id'] }
      end
    end

    actual = deserializable_klass.(@payload)
    expected = {
      post_ids: %w(123 234 345)
    }

    expect(actual).to eq(expected)
  end

  it 'works' do
    deserializable_klass = Class.new(JSONAPI::Deserializable::Resource) do
      id
      attribute(:name) { |name| field username: name }
      attribute :address
      has_one :sponsor do |_, id|
        field sponsor_id: id
      end
      has_many :posts do |_, ids|
        field post_ids: ids
      end
    end

    actual = deserializable_klass.(@payload)
    expected = {
      id: '1',
      username: 'Name',
      address: 'Address',
      sponsor_id: '1337',
      post_ids: %w(123 234 345)
    }

    expect(actual).to eq(expected)
  end
end
