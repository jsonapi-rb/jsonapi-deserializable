module JSONAPI
  module Deserializable
    module RelationshipDSL
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def has_one(&block)
          self.has_one_block = block
        end

        def has_many(&block)
          self.has_many_block = block
        end
      end
    end
  end
end
