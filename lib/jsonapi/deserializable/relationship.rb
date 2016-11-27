require 'jsonapi/deserializable/relationship/dsl'
require 'jsonapi/parser/relationship'

module JSONAPI
  module Deserializable
    class Relationship
      extend DSL

      class << self
        attr_accessor :has_one_block, :has_many_block
      end

      def self.inherited(klass)
        super
        klass.has_one_block  = has_one_block
        klass.has_many_block = has_many_block
      end

      def self.call(payload)
        new(payload).to_h
      end

      def initialize(payload)
        Parser::Relationship.parse!(payload)
        @document = payload
        @data = payload['data']
        deserialize!
        freeze
      end

      def to_hash
        @hash
      end
      alias to_h to_hash

      private

      def deserialize!
        @hash =
          if @data.is_a?(Array)
            deserialize_has_many
          elsif @data.nil? || @data.is_a?(Hash)
            deserialize_has_one
          end
      end

      def deserialize_has_one
        id = @data && @data['id']
        type = @data && @data['type']
        if self.class.has_one_block
          self.class.has_one_block.call(@document, id, type)
        else
          { id: id, type: type }
        end
      end

      def deserialize_has_many
        ids = @data.map { |ri| ri['id'] }
        types = @data.map { |ri| ri['type'] }
        if self.class.has_many_block
          self.class.has_many_block.call(@document, ids, types)
        else
          { ids: ids, types: types }
        end
      end
    end
  end
end
