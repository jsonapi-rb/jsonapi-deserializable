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
        _deserialize!
      end

      def to_hash
        @hash
      end
      alias to_h to_hash

      private

      def deserialize_has_one(_rel, id, type)
        { id: id, type: type }
      end

      def deserialize_has_many(_rel, ids, types)
        { ids: ids, types: types }
      end

      def _deserialize!
        unless @document.key?('data')
          @hash = {}
          return
        end

        @hash =
          if @data.is_a?(Array)
            _deserialize_has_many
          elsif @data.nil? || @data.is_a?(Hash)
            _deserialize_has_one
          end
      end

      def _deserialize_has_one
        id = @data && @data['id']
        type = @data && @data['type']
        if self.class.has_one_block
          self.class.has_one_block.call(@document, id, type)
        else
          deserialize_has_one(@document, id, type)
        end
      end

      def _deserialize_has_many
        ids = @data.map { |ri| ri['id'] }
        types = @data.map { |ri| ri['type'] }
        if self.class.has_many_block
          self.class.has_many_block.call(@document, ids, types)
        else
          deserialize_has_many(@document, ids, types)
        end
      end
    end
  end
end
