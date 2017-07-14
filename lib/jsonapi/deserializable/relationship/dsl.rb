module JSONAPI
  module Deserializable
    class Relationship
      module DSL
        DEFAULT_HAS_ONE_REL_BLOCK = proc do |_val, id, type|
          { type: type, id: id }
        end
        DEFAULT_HAS_MANY_REL_BLOCK = proc do |_val, ids, types|
          { types: types, ids: ids }
        end

        def has_one(&block)
          self.has_one_block = block || DEFAULT_HAS_ONE_REL_BLOCK
        end

        def has_many(&block)
          self.has_many_block = block || DEFAULT_HAS_MANY_REL_BLOCK
        end
      end
    end
  end
end
