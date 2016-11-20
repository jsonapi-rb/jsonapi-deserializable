require 'jsonapi/deserializable/relationship_dsl'

module JSONAPI
  module Deserializable
    class Relationship
      include RelationshipDSL

      class << self
        attr_accessor :has_one_block, :has_many_block
      end

      def self.inherited(klass)
        klass.has_one_block  = has_one_block
        klass.has_many_block = has_many_block
      end

      def self.call(payload)
        new(payload).to_h
      end

      def initialize(payload)
        @document = payload
        @data = payload['data']
        deserialize!
      end

      def to_hash
        @hash
      end
      alias to_h to_hash

      private

      def deserialize!
        @hash = {}
        return unless @document.key?('data')
        if @data.is_a?(Array)
          deserialize_has_many!
        elsif @data.nil? || @data.is_a?(Hash)
          deserialize_has_one!
        end
      end

      def deserialize_has_one!
        return unless self.class.has_one_block
        id = @data && @data['id']
        type = @data && @data['type']
        instance_exec(@document, id, type, &self.class.has_one_block)
      end

      def deserialize_has_many!
        return unless self.class.has_many_block
        ids = @data.map { |ri| ri['id'] }
        types = @data.map { |ri| ri['type'] }
        instance_exec(@document, ids, types, &self.class.has_many_block)
      end

      def field(hash)
        @hash.merge!(hash)
      end
    end
  end
end
