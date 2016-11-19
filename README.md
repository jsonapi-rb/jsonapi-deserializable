# jsonapi-deserializable
Ruby gem for deserializing [JSON API](http://jsonapi.org) payloads into custom
hashes.

## Status

[![Gem Version](https://badge.fury.io/rb/jsonapi-deserializable.svg)](https://badge.fury.io/rb/jsonapi-deserializable)
[![Build Status](https://secure.travis-ci.org/jsonapi-rb/deserializable.svg?branch=master)](http://travis-ci.org/jsonapi-rb/deserializable?branch=master)
[![codecov](https://codecov.io/gh/jsonapi-rb/deserializable/branch/master/graph/badge.svg)](https://codecov.io/gh/jsonapi-rb/deserializable)

## Table of Contents

  - [Installation](#installation)
  - [Usage/Examples](#usageexamples)
  - [Documentation](#documentation)
    - [Common methods](#common-methods)
    - [`JSONAPI::Deserializable::Resource` DSL](#jsonapideserializableresource-dsl)
    - [`JSONAPI::Deserializable::Relationship` DSL](#jsonapideserializablerelationship-dsl)
  - [License](#license)

## Installation
```ruby
# In Gemfile
gem 'jsonapi-deserializable'
```
then
```
$ bundle
```
or manually via
```
$ gem install jsonapi-deserializable
```

## Usage/Examples

First, require the gem:
```ruby
require 'jsonapi/deserializable'
```

Then, define some resource/relationship deserializable classes:

### Resource Example

```ruby
class DeserializablePost < JSONAPI::Deserializable::Resource
  type
  attribute :title
  attribute :date { |date| field date: DateTime.parse(date) }
  has_one :author do |rel, id, type|
    field author_id: id
    field author_type: type
  end
  has_many :comments do |rel, ids, types|
    field comment_ids: ids
    field comment_types: types.map do |type|
      camelize(singularize(type))
    end
  end
end
```

which can then be used to deserialize post payloads:
```ruby
DeserializablePost.(payload)
# => {
#      id: '1',
#      title: 'Title',
#      date: #<DateTime: 2016-01-10T02:30:00+00:00 ((2457398j,9000s,0n),+0s,2299161j)>,
#      author_id: '1337',
#      author_type: 'users',
#      comment_ids: ['123', '234', '345']
#      comment_types: ['Comment', 'Comment', 'Comment']
#    }
```

### Relationship Example

```ruby
class DeserializablePostComments < JSONAPI::Deserializable::Relationship
  has_many do |rel, ids, types|
    field comment_ids: ids
    field comment_types: types.map do |ri|
      camelize(singularize(type))
    end
    field comments_meta: rel['meta']
  end
end
```
```ruby
DeserializablePostComments.(payload)
# => {
#      comment_ids: ['123', '234', '345']
#      comment_types: ['Comment', 'Comment', 'Comment']
#    }
```

## Documentation

Whether deserializaing a resource or a relationship, the base idea is the same:
for every part of the payload, simply declare the fields you want to build from
their value. You can create as many fields as you want out of any one part of
the payload.

It works according to a whitelisting mechanism: should the corresponding part of
the payload not be present, the fields will simply not be created on the result
hash.

Note however that the library expects well formed JSONAPI payloads (which you
can ensure using, for instance,
[jsonapi-parser](https://github.com/beauby/jsonapi/tree/master/parser)),
and that deserialization does not substitute itself to validation of the
resulting hash (which you can handle using, for instance,
[dry-validation](http://dry-rb.org/gems/dry-validation/)).

### Common Methods

+ `::field(hash)`

The `field` DSL method is the base of jsonapi-deserializable. It simply declares
a field of the result hash, with its value. The syntax is:
```ruby
field key: value
```

It is mainly used within the following DSL contexts, but can be used outside of
any to declare custom non payload-related fields.

+ `#initialize(payload)`

Build a deserializable instance, ready to be deserialized by calling `#to_h`.

+ `#to_h`

In order to deserialize a payload, simply do:
```ruby
DeserializablePost.new(payload).to_h
```
or use the shorthand syntax:
```ruby
DeserializablePost.(payload)
```

### `JSONAPI::Deserializable::Resource` DSL

+ `::type(&block)`
```ruby
type do |type|
  field my_type_field: type
end
```

Shorthand syntax:
```ruby
type
```

+ `::id(&block)`
```ruby
id do |id|
  field my_id_field: id
end
```

Shorthand syntax:
```ruby
id
```

+ `::attribute(key, &block)`
```ruby
attribute :title do |title|
  field my_title_field: title
end
```

Shorthand syntax:
```ruby
attribute :title
```

+ `::has_one(key, &block)`
```ruby
has_one :author do |rel, id, type|
  field my_author_type_field: type
  field my_author_id_field: id
  field my_author_meta_field: rel['meta']
end
```

Shorthand syntax:
```ruby
has_one :author
```
Note: this creates a field `:author` with value the whole relationship hash.

+ `::has_many(key, &block)`
```ruby
has_many :comments do |rel, ids, types|
  field my_comment_types_field: types
  field my_comment_ids_field: ids
  field my_comment_meta_field: rel['meta']
end
```

Shorthand syntax:
```ruby
has_many :comments
```
Note: this creates a field `:comments` with value the whole relationship hash.

### `JSONAPI::Deserializable::Relationship` DSL

+ `::has_one(key, &block)`
```ruby
has_one do |rel, id, type|
  field my_relationship_id_field: id
  field my_relationship_type_field: type
  field my_relationship_meta_field: rel['meta']
end
```

+ `has_many(key, &block)`
```ruby
has_many do |rel, ids, types|
  field my_relationship_ids_field: ids
  field my_relationship_types_field: types
  field my_relationship_meta_field: rel['meta']
end
```

## License

jsonapi-deserializable is released under the [MIT License](http://www.opensource.org/licenses/MIT).
