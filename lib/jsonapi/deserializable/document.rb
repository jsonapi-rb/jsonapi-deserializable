require 'jsonapi/deserializable/document/validator'
require 'jsonapi/deserializable/document/processor'

module JSONAPI
  module Deserializable
    class Document
      def initialize(payload)
        @payload = payload
      end

      attr_reader :payload

      def resource(pointer)
        path = pointer
                 .split('/')
                 .map { |p| p.gsub('~1', '/').gsub('~0', '~') }
                 .map { |p| /^(0|[1-9][0-9]*)$/ =~ p ? p.to_i : p }

        begin
          @payload.dig(*path[1..-1])
        rescue NoMethodError # Polyfill for ruby < 2.3
          path[1..-1].inject(@payload) { |a, p| a[p] }
        end
      end

      def validate(wl, &block)
        @validator ||= Validator.new(self)
        @validator.validate(wl, &block)
      end

      def process(order = {}, &block)
        Processor.new(self, order).process(&block)
      end
    end
  end
end
