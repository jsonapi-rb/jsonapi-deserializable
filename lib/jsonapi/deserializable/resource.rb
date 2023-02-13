require 'jsonapi/deserializable/resource/dsl'

module JSONAPI
  module Deserializable
    class Resource
      extend DSL

      class << self
        attr_accessor :type_block, :id_block, :attr_blocks,
                      :has_one_rel_blocks, :has_many_rel_blocks,
                      :has_one_rel_options, :has_many_rel_options,
                      :default_attr_block, :default_has_one_rel_block,
                      :default_has_many_rel_block,
                      :key_formatter
      end

      self.attr_blocks         = {}
      self.has_one_rel_blocks  = {}
      self.has_many_rel_blocks = {}

      self.has_one_rel_options  = {}
      self.has_many_rel_options = {}

      self.key_formatter       = proc { |k| k }

      def self.inherited(klass)
        super
        klass.type_block          = type_block
        klass.id_block            = id_block
        klass.attr_blocks         = attr_blocks.dup
        klass.has_one_rel_blocks  = has_one_rel_blocks.dup
        klass.has_many_rel_blocks = has_many_rel_blocks.dup

        klass.has_one_rel_options  = has_one_rel_options.dup
        klass.has_many_rel_options = has_many_rel_options.dup

        klass.default_attr_block  = default_attr_block
        klass.default_has_one_rel_block   = default_has_one_rel_block
        klass.default_has_many_rel_block  = default_has_many_rel_block
        klass.key_formatter = key_formatter
      end

      def self.call(payload)
        new(payload).to_h
      end

      def initialize(payload, root: '/data')
        @data = ((payload || {}).key?('data') ? payload['data'] : payload) || {}

        @root = root
        @type = @data['type']
        @id   = @data['id']
        @attributes    = @data['attributes'] || {}
        @relationships = @data['relationships'] || {}

        # Objectifies each included object 
        @included = initialize_included(payload.key?('included') ? payload['included'] : [])

        deserialize!

        freeze
      end

      def to_hash
        @hash
      end
      alias to_h to_hash

      attr_reader :reverse_mapping, :key_to_type_mapping

      private

      def initialize_included(included)
        return nil unless included.present?

        # For each included, create an object of the correct type
        included.map do |data|

          # Find the key of type 
          key = key_to_type_mapping_inverted[data['type']&.to_s&.to_sym]

          # Finds the deserializer
          deserializer = merged_rel_options&.[](key)&.[](:deserializer)

          # If the deserializer is not available, uses the current class to create the object
          if deserializer.blank?
            # Important to wrap this around this hash. This will be crucial for use in method `find_in_included/2` defined in the same class. 
            # If the deserializer is created using the current class, we will need to pluck all its attributes
            { has_deserializer: false, object: self.class.new({ 'data' => data }) }
          else

            # If the deserializer is created using a given class, we will need to call .to_h on it instead of plucking all its attributes
            { has_deserializer: true, object: deserializer.new({ 'data' => data }) }
          end
        end
      end

      def included_types
        return [] unless @included.present?
        @included.map { |doc| doc.instance_variable_get(:@type) }.uniq
      end

      def register_mappings(keys, path)
        keys.each do |k|
          @reverse_mapping[k] = @root + path
        end
      end

      def key_to_type_mapping_inverted
        # Goes through the options of has_many / has_one and creates a hash of type => key
        # Example: { books: 'books', people: 'author' }
        # In the example above, people is the type of the objects in "included", but the name of the key is 'author'
        # It creates this mapping so that to find the right derserializer for the given key (if any)
        self.class.has_one_rel_options.map { |h, k| { h => k[:type]} }.reduce({}, :merge).invert.merge(
          self.class.has_many_rel_options.map { |h, k| { h => k[:type]} }.reduce({}, :merge) 
        )
      end

      def merged_rel_options
        self.class.has_one_rel_options.merge(self.class.has_many_rel_options)
      end

      def deserialize!
        @reverse_mapping = {}
        hashes = [deserialize_type, deserialize_id,
                  deserialize_attrs, deserialize_rels]
        @hash = hashes.reduce({}, :merge)
      end

      def deserialize_type
        block = self.class.type_block
        return {} unless block

        hash = block.call(@type)
        register_mappings(hash.keys, '/type')
        hash
      end

      def deserialize_id
        block = self.class.id_block
        return {} unless @id && block

        hash = block.call(@id)
        register_mappings(hash.keys, '/id')
        hash
      end

      def deserialize_attrs
        @attributes
          .map { |key, val| deserialize_attr(key, val) }
          .reduce({}, :merge)
      end

      def deserialize_attr(key, val)
        block = self.class.attr_blocks[key] || self.class.default_attr_block
        return {} unless block

        hash = block.call(val, self.class.key_formatter.call(key))
        register_mappings(hash.keys, "/attributes/#{key}")
        hash
      end

      def deserialize_rels
       @relationships
          .map { |key, val| deserialize_rel(key, val) }
          .reduce({}, :merge)
      end

      def deserialize_rel(key, val)
        if val['data'].is_a?(Array)
          deserialize_has_many_rel(key, val)
        else
          deserialize_has_one_rel(key, val)
        end
      end

      # rubocop: disable Metrics/AbcSize
      def deserialize_has_one_rel(key, val)
        block = self.class.has_one_rel_blocks[key] ||
                self.class.default_has_one_rel_block

        options = self.class.has_one_rel_options[key] || {}

        return {} unless block

        id   = val['data'] && val['data']['id']
        type = val['data'] && val['data']['type']
        hash = block.call(val, id, type, self.class.key_formatter.call(key))
        
        register_mappings(hash.keys, "/relationships/#{key}")

        if options.[](:with_included)
          return {**hash, key.to_sym => find_in_included(id:, type:)}
        end
        
        hash
      end
      # rubocop: enable Metrics/AbcSize

      # rubocop: disable Metrics/AbcSize
      def deserialize_has_many_rel(key, val)
        block = self.class.has_many_rel_blocks[key] ||
                self.class.default_has_many_rel_block


        options = self.class.has_many_rel_options[key] || {}
        
        return {} unless block && val['data'].is_a?(Array)

        ids   = val['data'].map { |ri| ri['id'] }
        types = val['data'].map { |ri| ri['type'] }
        hash = block.call(val, ids, types, self.class.key_formatter.call(key))

        register_mappings(hash.keys, "/relationships/#{key}")

        if options.[](:with_included)
          return {**hash, key.to_sym => ids.map { |id| find_in_included(id: id, type: types[ids.index(id)]) }}
        end

        hash
      end

      def find_in_included(id:, type:)
        # Cross referencing the relationship id and type with the included objects
        cross_reference = @included.select { |doc| doc[:object]&.instance_variable_get(:@id) == id && doc[:object].instance_variable_get(:@type) == type  }&.first

        # If the deserializer is created using a given class, we will need to call .to_h on it instead of plucking all its attributes
        cross_reference[:has_deserializer] ? cross_reference[:object].to_h : cross_reference[:object].instance_variable_get(:@attributes).to_h
      end
      # rubocop: enable Metrics/AbcSize
    end
  end
end
