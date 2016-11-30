require 'jsonapi/deserializable/resource/configuration'
require 'jsonapi/deserializable/resource/dsl'

module JSONAPI
  module Deserializable
    class Resource
      extend DSL

      class << self
        attr_accessor :type_block, :id_block, :attr_blocks,
                      :has_one_rel_blocks, :has_many_rel_blocks,
                      :configuration
      end

      @class_cache = {}

      self.configuration       = Configuration.new
      self.attr_blocks         = {}
      self.has_one_rel_blocks  = {}
      self.has_many_rel_blocks = {}

      def self.inherited(klass)
        super
        klass.configuration       = configuration.dup
        klass.type_block          = type_block
        klass.id_block            = id_block
        klass.attr_blocks         = attr_blocks.dup
        klass.has_one_rel_blocks  = has_one_rel_blocks.dup
        klass.has_many_rel_blocks = has_many_rel_blocks.dup
      end

      def self.configure
        yield(configuration)
      end

      def self.[](name)
        @class_cache[name] ||= Class.new(self)
      end

      def self.call(payload)
        new(payload).to_h
      end

      def initialize(payload)
        @document = payload
        @data = @document['data']
        @type = @data['type']
        @id   = @data['id']
        @attributes    = @data['attributes'] || {}
        @relationships = @data['relationships'] || {}
        deserialize!
        freeze
      end

      def to_hash
        @hash
      end
      alias to_h to_hash

      attr_reader :reverse_mapping

      private

      def configuration
        self.class.configuration
      end

      def register_mappings(keys, path)
        keys.each do |k|
          @reverse_mapping[k] = path
        end
      end

      def deserialize!
        @reverse_mapping = {}
        hashes = [deserialize_type, deserialize_id,
                  deserialize_attrs, deserialize_rels]
        @hash = hashes.reduce({}, :merge)
      end

      def deserialize_type
        block = self.class.type_block || configuration.default_type
        hash = block.call(@type)
        register_mappings(hash.keys, '/data/type')
        hash
      end

      def deserialize_id
        return {} unless @id
        block = self.class.id_block || configuration.default_id
        hash  = block.call(@id)
        register_mappings(hash.keys, '/data/id')
        hash
      end

      def deserialize_attrs
        @attributes
          .map { |key, val| deserialize_attr(key, val) }
          .reduce({}, :merge)
      end

      def deserialize_attr(key, val)
        hash = if self.class.attr_blocks.key?(key)
                 self.class.attr_blocks[key].call(val)
               else
                 configuration.default_attribute.call(key, val)
               end
        register_mappings(hash.keys, "/data/attributes/#{key}")
        hash
      end

      def deserialize_rels
        @relationships
          .map { |key, val| deserialize_rel(key, val) }
          .reduce({}, :merge)
      end

      def deserialize_rel(key, val)
        hash = if val['data'].is_a?(Array)
                 deserialize_has_many_rel(key, val)
               else
                 deserialize_has_one_rel(key, val)
               end
        register_mappings(hash.keys, "/data/relationships/#{key}")
        hash
      end

      # rubocop: disable Metrics/AbcSize
      def deserialize_has_one_rel(key, val)
        id   = val['data'] && val['data']['id']
        type = val['data'] && val['data']['type']
        if self.class.has_one_rel_blocks.key?(key)
          self.class.has_one_rel_blocks[key].call(val, id, type)
        else
          configuration.default_has_one.call(key, val, id, type)
        end
      end
      # rubocop: enable Metrics/AbcSize

      # rubocop: disable Metrics/AbcSize
      def deserialize_has_many_rel(key, val)
        ids   = val['data'].map { |ri| ri['id'] }
        types = val['data'].map { |ri| ri['type'] }
        if self.class.has_many_rel_blocks.key?(key)
          self.class.has_many_rel_blocks[key].call(val, ids, types)
        else
          configuration.default_has_many.call(key, val, ids, types)
        end
      end
      # rubocop: enable Metrics/AbcSize
    end
  end
end
