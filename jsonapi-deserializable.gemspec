version = File.read(File.expand_path('../VERSION', __FILE__)).strip

Gem::Specification.new do |spec|
  spec.name          = 'jsonapi-deserializable'
  spec.version       = version
  spec.author        = 'Lucas Hosseini'
  spec.email         = 'lucas.hosseini@gmail.com'
  spec.summary       = 'Deserialize JSON API payloads.'
  spec.description   = 'DSL for deserializing incoming JSON API payloads ' \
                       'into custom hashes.'
  spec.homepage      = 'https://github.com/jsonapi-rb/jsonapi-deserializable'
  spec.license       = 'MIT'

  spec.files         = Dir['README.md', 'lib/**/*']
  spec.require_path  = 'lib'

  spec.add_development_dependency 'rake',    '~> 11.3'
  spec.add_development_dependency 'rspec',   '~> 3.4'
  spec.add_development_dependency 'codecov', '~> 0.1'
end
