require 'jsonapi/deserializable/resource_dsl'

module JSONAPI
  module Deserializable
    class Resource
      include ResourceDSL

      class << self
        attr_accessor :type_block, :id_block
        attr_accessor :attr_blocks
        attr_accessor :has_one_rel_blocks, :has_many_rel_blocks
      end

      self.attr_blocks = {}
      self.has_one_rel_blocks = {}
      self.has_many_rel_blocks = {}

      def self.inherited(klass)
        super
        klass.type_block  = type_block
        klass.id_block    = id_block
        klass.attr_blocks = attr_blocks.dup
        klass.has_one_rel_blocks  = has_one_rel_blocks.dup
        klass.has_many_rel_blocks = has_many_rel_blocks.dup
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
      end

      def to_h
        @hash
      end

      private

      def deserialize!
        @hash = {}
        deserialize_type!
        deserialize_id!
        deserialize_attrs!
        deserialize_rels!
      end

      def deserialize_type!
        return unless @type && self.class.type_block
        instance_exec(@type, &self.class.type_block)
      end

      def deserialize_id!
        return unless @id && self.class.id_block
        instance_exec(@id, &self.class.id_block)
      end

      def deserialize_attrs!
        self.class.attr_blocks.each do |attr, block|
          next unless @attributes.key?(attr)
          instance_exec(@attributes[attr], &block)
        end
      end

      def deserialize_rels!
        deserialize_has_one_rels!
        deserialize_has_many_rels!
      end

      def deserialize_has_one_rels!
        self.class.has_one_rel_blocks.each do |key, block|
          rel = @relationships[key]
          next unless rel && (rel['data'].nil? || rel['data'].is_a?(Hash))
          deserialize_has_one_rel!(rel, &block)
        end
      end

      def deserialize_has_one_rel!(rel, &block)
        id = rel['data'] && rel['data']['id']
        type = rel['data'] && rel['data']['type']
        instance_exec(rel, id, type, &block)
      end

      def deserialize_has_many_rels!
        self.class.has_many_rel_blocks.each do |key, block|
          rel = @relationships[key]
          next unless rel && rel['data'].is_a?(Array)
          deserialize_has_many_rel!(rel, &block)
        end
      end

      def deserialize_has_many_rel!(rel, &block)
        ids = rel['data'].map { |ri| ri['id'] }
        types = rel['data'].map { |ri| ri['type'] }
        instance_exec(rel, ids, types, &block)
      end

      def field(hash)
        @hash.merge!(hash)
      end
    end
  end
end
