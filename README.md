# jsonapi-deserializable
Ruby gem for deserializing [JSON API](http://jsonapi.org) payloads into custom
hashes.



## Usage

#### Support for included documents

To insert the included documents to ``has_one`` and ``has_many`` relation ship, use the ``with_included: true`` option to the relationship:

```ruby
class DeserializableBook < JSONAPI::Deserializable::Resource
    id
    type
    attributes :id,
               :title

    has_one :author, with_included: true
end
```



To use a custom deserializer for the included relationship, use the ``deserializer`` option:

```ruby
class DeserializableBook < JSONAPI::Deserializable::Resource
    id
    type
    attributes :id,
               :title

    has_one :author, with_included: true, deserializer: DeserialzableAuthor
end
```



If the property name is different than the included object type, pass the ``type`` option:



```ruby
class DeserializableBook < JSONAPI::Deserializable::Resource
    id
    type
    attributes :id,
               :title

    has_one :author, with_included: true, deserializer: DeserializablePerson, type: 'people'
end
```

## Status

[![Gem Version](https://badge.fury.io/rb/jsonapi-deserializable.svg)](https://badge.fury.io/rb/jsonapi-deserializable)
[![Build Status](https://secure.travis-ci.org/jsonapi-rb/jsonapi-deserializable.svg?branch=master)](http://travis-ci.org/jsonapi-rb/deserializable?branch=master)
[![codecov](https://codecov.io/gh/jsonapi-rb/jsonapi-deserializable/branch/master/graph/badge.svg)](https://codecov.io/gh/jsonapi-rb/deserializable)
[![Gitter chat](https://badges.gitter.im/gitterHQ/gitter.png)](https://gitter.im/jsonapi-rb/Lobby)

## Resources

* Chat: [gitter](http://gitter.im/jsonapi-rb)
* Twitter: [@jsonapirb](http://twitter.com/jsonapirb)
* Docs: [jsonapi-rb.org](http://jsonapi-rb.org)

## Usage and documentation

See [jsonapi-rb.org/guides/deserialization](http://jsonapi-rb.org/guides/deserialization).

## License

jsonapi-deserializable is released under the [MIT License](http://www.opensource.org/licenses/MIT).
