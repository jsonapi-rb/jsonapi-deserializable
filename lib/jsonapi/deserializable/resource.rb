require 'jsonapi/deserializable/resource_dsl'
require 'jsonapi/parser/resource'

module JSONAPI
  module Deserializable
    class Resource
      DEFAULT_TYPE_BLOCK = proc { |t| { type: t } }
      DEFAULT_ID_BLOCK   = proc { |i| { id: i } }
      DEFAULT_ATTR_BLOCK = proc { |k, v| { k.to_sym => v } }
      DEFAULT_HAS_ONE_BLOCK = proc do |k, _, i, t|
        { "#{k}_id".to_sym => i, "#{k}_type".to_sym => t }
      end
      DEFAULT_HAS_MANY_BLOCK = proc do |k, _, i, t|
        { "#{k}_ids".to_sym => i, "#{k}_types".to_sym => t }
      end

      include ResourceDSL

      class << self
        attr_accessor :type_block, :id_block, :attr_blocks,
                      :has_one_rel_blocks, :has_many_rel_blocks,
                      :default_attr_block, :default_has_one_block,
                      :default_has_many_block
      end

      self.attr_blocks = {}
      self.has_one_rel_blocks  = {}
      self.has_many_rel_blocks = {}
      self.type_block = DEFAULT_TYPE_BLOCK
      self.id_block   = DEFAULT_ID_BLOCK
      self.default_attr_block     = DEFAULT_ATTR_BLOCK
      self.default_has_one_block  = DEFAULT_HAS_ONE_BLOCK
      self.default_has_many_block = DEFAULT_HAS_MANY_BLOCK

      def self.inherited(klass)
        super
        klass.type_block  = type_block
        klass.id_block    = id_block
        klass.attr_blocks         = attr_blocks.dup
        klass.has_one_rel_blocks  = has_one_rel_blocks.dup
        klass.has_many_rel_blocks = has_many_rel_blocks.dup
        klass.default_attr_block     = default_attr_block
        klass.default_has_one_block  = default_has_one_block
        klass.default_has_many_block = default_has_many_block
      end

      def self.call(payload)
        new(payload).to_h
      end

      def initialize(payload)
        Parser::Resource.parse!(payload)
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

      def deserialize!
        @hash = {}
        @reverse_mapping = {}
        deserialize_type!
        deserialize_id!
        deserialize_attrs!
        deserialize_rels!
      end

      def register_hash!(hash, path)
        hash.keys.each do |k|
          @reverse_mapping[k] = path
        end
        @hash.merge!(hash)
      end

      def deserialize_type!
        type_hash = self.class.type_block.call(@type)
        register_hash!(type_hash, '/data/type')
      end

      def deserialize_id!
        return unless @id
        id_hash = self.class.id_block.call(@id)
        register_hash!(id_hash, '/data/id')
      end

      def deserialize_attrs!
        @attributes.each do |key, val|
          hash = if self.class.attr_blocks.key?(key)
                   self.class.attr_blocks[key].call(val)
                 else
                   self.class.default_attr_block.call(key, val)
                 end
          register_hash!(hash, "/data/attributes/#{key}")
        end
      end

      def deserialize_rels!
        @relationships.each do |key, val|
          hash = if val['data'].is_a?(Array)
                   deserialize_has_many_rel(key, val)
                 else
                   deserialize_has_one_rel(key, val)
                 end
          register_hash!(hash, "/data/relationships/#{key}")
        end
      end

      # rubocop: disable Metrics/AbcSize
      def deserialize_has_one_rel(key, val)
        id   = val['data'] && val['data']['id']
        type = val['data'] && val['data']['type']
        if self.class.has_one_rel_blocks.key?(key)
          self.class.has_one_rel_blocks[key].call(val, id, type)
        else
          self.class.default_has_one_block.call(key, val, id, type)
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
          self.class.default_has_many_block.call(key, val, ids, types)
        end
      end
      # rubocop: enable Metrics/AbcSize
    end
  end
end
