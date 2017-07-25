require 'jsonapi/deserializable/relationship/dsl'

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
        block = self.class.has_one_block
        return {} unless block
        id = @data && @data['id']
        type = @data && @data['type']
        block.call(@document, id, type)
      end

      def deserialize_has_many
        block = self.class.has_many_block
        return {} unless block && @data.is_a?(Array)
        ids = @data.map { |ri| ri['id'] }
        types = @data.map { |ri| ri['type'] }
        block.call(@document, ids, types)
      end
    end
  end
end
