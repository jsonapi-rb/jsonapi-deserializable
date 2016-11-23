require 'jsonapi/deserializable/resource_dsl'
require 'jsonapi/parser/resource'

module JSONAPI
  module Deserializable
    class Resource
      include ResourceDSL

      class << self
        attr_accessor :type_block, :id_block, :attr_blocks,
                      :has_one_rel_blocks, :has_many_rel_blocks
      end

      self.attr_blocks = {}
      self.has_one_rel_blocks  = {}
      self.has_many_rel_blocks = {}

      def self.inherited(klass)
        super
        klass.type_block  = type_block
        klass.id_block    = id_block
        klass.attr_blocks         = attr_blocks.dup
        klass.has_one_rel_blocks  = has_one_rel_blocks.dup
        klass.has_many_rel_blocks = has_many_rel_blocks.dup
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

      private

      def deserialize_type(type)
        { type: type }
      end

      def deserialize_id(id)
        { id: id }
      end

      def deserialize_attribute(key, value)
        { key.to_sym => value }
      end

      def deserialize_has_one(key, _value, id, type)
        { "#{key}_type".to_sym => type, "#{key}_id".to_sym => id }
      end

      def deserialize_has_many(key, _value, ids, types)
        { "#{key}_types".to_sym => types, "#{key}_ids".to_sym => ids }
      end

      def deserialize!
        @hash = {}
        _deserialize_type!
        _deserialize_id!
        _deserialize_attrs!
        _deserialize_rels!
      end

      def _deserialize_type!
        @hash.merge!(
          if self.class.type_block
            self.class.type_block.call(@type)
          else
            deserialize_type(@type)
          end
        )
      end

      def _deserialize_id!
        return unless @id
        @hash.merge!(
          if self.class.id_block
            self.class.id_block.call(@id)
          else
            deserialize_id(@id)
          end
        )
      end

      def _deserialize_attrs!
        @attributes.each do |key, val|
          if self.class.attr_blocks.key?(key)
            @hash.merge!(self.class.attr_blocks[key].call(val))
          else
            @hash.merge!(deserialize_attribute(key, val))
          end
        end
      end

      def _deserialize_rels!
        @relationships.each do |key, val|
          if val['data'].is_a?(Array)
            @hash.merge!(_deserialize_has_many_rel(key, val))
          else
            @hash.merge!(_deserialize_has_one_rel(key, val))
          end
        end
      end

      def _deserialize_has_one_rel(key, val)
        id   = val['data'] && val['data']['id']
        type = val['data'] && val['data']['type']
        if self.class.has_one_rel_blocks.key?(key)
          self.class.has_one_rel_blocks[key].call(val, id, type)
        else
          deserialize_has_one(key, val, id, type)
        end
      end

      def _deserialize_has_many_rel(key, val)
        ids   = val['data'].map { |ri| ri['id'] }
        types = val['data'].map { |ri| ri['type'] }
        if self.class.has_many_rel_blocks.key?(key)
          self.class.has_many_rel_blocks[key].call(val, ids, types)
        else
          deserialize_has_many(key, val, ids, types)
        end
      end
    end
  end
end
