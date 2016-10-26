module JSONAPI
  module Deserializable
    module RelationshipDSL
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def has_one(&block)
          block ||= proc { |rel| field key.to_sym => rel }
          self.has_one_block = block
        end

        def has_many(&block)
          block ||= proc { |rel| field key.to_sym => rel }
          self.has_many_block = block
        end
      end
    end
  end
end
