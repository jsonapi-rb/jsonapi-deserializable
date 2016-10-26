module JSONAPI
  module Deserializable
    module ResourceDSL
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def type(&block)
          block ||= proc { |type| field type: type }
          self.type_block = block
        end

        def id(&block)
          block ||= proc { |id| field id: id }
          self.id_block = block
        end

        def attribute(key, options = {}, &block)
          unless block
            options[:key] ||= key.to_sym
            block = proc { |attr| field key => attr }
          end
          attr_blocks[key.to_s] = block
        end

        def has_one(key, &block)
          block ||= proc { |rel| field key.to_sym => rel }
          has_one_rel_blocks[key.to_s] = block
        end

        def has_many(key, &block)
          block ||= proc { |rel| field key.to_sym => rel }
          has_many_rel_blocks[key.to_s] = block
        end
      end
    end
  end
end
