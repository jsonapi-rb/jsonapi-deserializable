require 'jsonapi/deserializable/document/validator'
require 'jsonapi/deserializable/document/processor'

module JSONAPI
  module Deserializable
    class Document
      def initialize(payload)
        @validator = Validator.new(payload)
        @processor = Processor.new(payload)
      end

      def validate(wl, &block)
        @validator.validate(wl, &block)
      end

      def process(&block)
        @processor.process(&block)
      end
    end
  end
end
