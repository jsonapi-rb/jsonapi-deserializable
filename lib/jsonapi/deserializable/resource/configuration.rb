module JSONAPI
  module Deserializable
    class Resource
      class Configuration
        DEFAULT_TYPE_BLOCK = proc { |t| { type: t } }
        DEFAULT_ID_BLOCK   = proc { |i| { id: i } }
        DEFAULT_ATTR_BLOCK = proc { |k, v| { k.to_sym => v } }
        DEFAULT_HAS_ONE_BLOCK = proc do |k, _, i, t|
          { "#{k}_id".to_sym => i, "#{k}_type".to_sym => t }
        end
        DEFAULT_HAS_MANY_BLOCK = proc do |k, _, i, t|
          { "#{k}_ids".to_sym => i, "#{k}_types".to_sym => t }
        end

        attr_accessor :default_type, :default_id, :default_attribute,
                      :default_has_one, :default_has_many

        def initialize
          self.default_type       = DEFAULT_TYPE_BLOCK
          self.default_id         = DEFAULT_ID_BLOCK
          self.default_attribute  = DEFAULT_ATTR_BLOCK
          self.default_has_one    = DEFAULT_HAS_ONE_BLOCK
          self.default_has_many   = DEFAULT_HAS_MANY_BLOCK
        end
      end
    end
  end
end
