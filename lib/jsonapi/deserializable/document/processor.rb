module JSONAPI
  module Deserializable
    class Document
      class Processor
        def initialize(document, edges_directions = {})
          @document = document
          @sorted_resources = sort_resources(edges_directions)

          freeze
        end

        def process
          {}.tap do |resources|
            @sorted_resources.each do |pointer|
              resources[pointer] = yield(pointer, @graph[pointer], resources)
            end
          end
        end

        private

        def _build_adjacencies(resource, pointer, order, adj)
          adj[pointer] ||= Set.new
          order = order[resource['type'].to_sym] || {}
          (resource['relationships'] || {}).each do |k, v|
            data = v['data'].is_a?(Array) ? v['data'] : [v['data']]
            data.each do |ri|
              next unless ri['pointer']
              if order[k.to_sym] == :backward
                adj[ri['pointer']].add pointer
              else
                adj[pointer].add ri['pointer']
              end
            end
          end
        end

        def build_adjacencies(order)
          adj = Hash.new { |h, k| h[k] = Set.new }
          _build_adjacencies(@document.payload['data'], '/data', order, adj)
          (@document.payload['included'] || []).each_with_index do |res, ind|
            _build_adjacencies(res, "/included/#{ind}", order, adj)
          end

          adj
        end

        def sort_resources(order)
          return if @document.payload['data'].nil?
          @graph = build_adjacencies(order)
          @state = {}

          sorted_resources = []
          @graph.each_key do |p|
            _sort_resources(p, sorted_resources)
          end

          sorted_resources
        end

        def _sort_resources(pointer, result)
          return if @state[pointer] == :visited
          raise 'Cycle detected' if @state[pointer] == :open
          @state[pointer] = :open

          @graph[pointer].each do |p|
            _sort_resources(p, result)
          end

          @state[pointer] = :visited
          result << pointer

          result
        end
      end
    end
  end
end
