module JSONAPI
  module Deserializable
    module ResourceDSL
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def type(&block)
          self.type_block = block
        end

        def id(&block)
          self.id_block = block
        end

        def attribute(key = nil, &block)
          if key.nil?
            self.default_attr_block = block
          else
            attr_blocks[key.to_s] = block
          end
        end

        def has_one(key = nil, &block)
          if key.nil?
            self.default_has_one_block = block
          else
            has_one_rel_blocks[key.to_s] = block
          end
        end

        def has_many(key = nil, &block)
          if key.nil?
            self.default_has_many_block = block
          else
            has_many_rel_blocks[key.to_s] = block
          end
        end
      end
    end
  end
end
