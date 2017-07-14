module JSONAPI
  module Deserializable
    class Resource
      module DSL
        DEFAULT_TYPE_BLOCK = proc { |t| { type: t } }
        DEFAULT_ID_BLOCK   = proc { |i| { id: i } }
        DEFAULT_ATTR_BLOCK = proc { |v, k| { k.to_sym => v } }
        DEFAULT_HAS_ONE_BLOCK = proc do |_, i, t, k|
          { "#{k}_id".to_sym => i, "#{k}_type".to_sym => t }
        end
        DEFAULT_HAS_MANY_BLOCK = proc do |_, i, t, k|
          { "#{k}_ids".to_sym => i, "#{k}_types".to_sym => t }
        end

        def type(&block)
          self.type_block = block || DEFAULT_TYPE_BLOCK
        end

        def id(&block)
          self.id_block = block || DEFAULT_ID_BLOCK
        end

        def attribute(key, &block)
          attr_blocks[key.to_s] = block || DEFAULT_ATTR_BLOCK
        end

        def attributes(*keys, &block)
          if keys.empty?
            self.default_attr_block = block || DEFAULT_ATTR_BLOCK
          else
            keys.each { |k| attribute(k, &block) }
          end
        end

        def has_one(key = nil, &block)
          if key
            has_one_rel_blocks[key.to_s] = block || DEFAULT_HAS_ONE_BLOCK
          else
            self.default_has_one_rel_block = block || DEFAULT_HAS_ONE_BLOCK
          end
        end

        def has_many(key = nil, &block)
          if key
            has_many_rel_blocks[key.to_s] = block || DEFAULT_HAS_MANY_BLOCK
          else
            self.default_has_many_rel_block = block || DEFAULT_HAS_MANY_BLOCK
          end
        end

        def key_format(callable = nil, &block)
          self.key_formatter = callable || block
        end
      end
    end
  end
end
