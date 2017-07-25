require 'jsonapi/deserializable/resource/dsl'

module JSONAPI
  module Deserializable
    class Resource
      extend DSL

      class << self
        attr_accessor :type_block, :id_block, :attr_blocks,
                      :has_one_rel_blocks, :has_many_rel_blocks,
                      :default_attr_block, :default_has_one_rel_block,
                      :default_has_many_rel_block,
                      :key_formatter
      end

      self.attr_blocks         = {}
      self.has_one_rel_blocks  = {}
      self.has_many_rel_blocks = {}
      self.key_formatter       = proc { |k| k }

      def self.inherited(klass)
        super
        klass.type_block          = type_block
        klass.id_block            = id_block
        klass.attr_blocks         = attr_blocks.dup
        klass.has_one_rel_blocks  = has_one_rel_blocks.dup
        klass.has_many_rel_blocks = has_many_rel_blocks.dup
        klass.default_attr_block  = default_attr_block
        klass.default_has_one_rel_block   = default_has_one_rel_block
        klass.default_has_many_rel_block  = default_has_many_rel_block
        klass.key_formatter = key_formatter
      end

      def self.call(payload)
        new(payload).to_h
      end

      def initialize(payload, root: '/data')
        @data = payload || {}
        @root = root
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

      def register_mappings(keys, path)
        keys.each do |k|
          @reverse_mapping[k] = @root + path
        end
      end

      def deserialize!
        @reverse_mapping = {}
        hashes = [deserialize_type, deserialize_id,
                  deserialize_attrs, deserialize_rels]
        @hash = hashes.reduce({}, :merge)
      end

      def deserialize_type
        block = self.class.type_block
        return {} unless block

        hash = block.call(@type)
        register_mappings(hash.keys, '/type')
        hash
      end

      def deserialize_id
        block = self.class.id_block
        return {} unless @id && block

        hash = block.call(@id)
        register_mappings(hash.keys, '/id')
        hash
      end

      def deserialize_attrs
        @attributes
          .map { |key, val| deserialize_attr(key, val) }
          .reduce({}, :merge)
      end

      def deserialize_attr(key, val)
        block = self.class.attr_blocks[key] || self.class.default_attr_block
        return {} unless block

        hash = block.call(val, self.class.key_formatter.call(key))
        register_mappings(hash.keys, "/attributes/#{key}")
        hash
      end

      def deserialize_rels
        @relationships
          .map { |key, val| deserialize_rel(key, val) }
          .reduce({}, :merge)
      end

      def deserialize_rel(key, val)
        if val['data'].is_a?(Array)
          deserialize_has_many_rel(key, val)
        else
          deserialize_has_one_rel(key, val)
        end
      end

      # rubocop: disable Metrics/AbcSize
      def deserialize_has_one_rel(key, val)
        block = self.class.has_one_rel_blocks[key] ||
                self.class.default_has_one_rel_block
        return {} unless block

        id   = val['data'] && val['data']['id']
        type = val['data'] && val['data']['type']
        hash = block.call(val, id, type, self.class.key_formatter.call(key))
        register_mappings(hash.keys, "/relationships/#{key}")
        hash
      end
      # rubocop: enable Metrics/AbcSize

      # rubocop: disable Metrics/AbcSize
      def deserialize_has_many_rel(key, val)
        block = self.class.has_many_rel_blocks[key] ||
                self.class.default_has_many_rel_block
        return {} unless block && val['data'].is_a?(Array)

        ids   = val['data'].map { |ri| ri['id'] }
        types = val['data'].map { |ri| ri['type'] }
        hash = block.call(val, ids, types, self.class.key_formatter.call(key))
        register_mappings(hash.keys, "/relationships/#{key}")
        hash
      end
      # rubocop: enable Metrics/AbcSize
    end
  end
end
