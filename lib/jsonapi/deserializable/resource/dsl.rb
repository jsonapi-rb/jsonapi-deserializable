module JSONAPI
  module Deserializable
    class Resource
      module DSL
        def type(&block)
          self.type_block = block
        end

        def id(&block)
          self.id_block = block
        end

        def attribute(key, &block)
          attr_blocks[key.to_s] = block
        end

        def has_one(key, &block)
          has_one_rel_blocks[key.to_s] = block
        end

        def has_many(key, &block)
          has_many_rel_blocks[key.to_s] = block
        end
      end
    end
  end
end
