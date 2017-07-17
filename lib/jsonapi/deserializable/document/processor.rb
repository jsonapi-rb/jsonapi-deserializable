module JSONAPI
  module Deserializable
    class Document
      class Processor
        def initialize(payload)
          @payload = payload
        end

        def process
          sort_resources unless @sorted_resources
          res_identifiers = {}
          @sorted_resources.each do |res, pointer|
            res = resolve_resource(res, res_identifiers)
            res_identifiers[pointer] = { 'id' => yield(res),
                                         'type' => res['type'] }
          end
        end

        private

        def _resource(pointer)
          path = pointer
                   .split('/')
                   .map { |p| p.gsub('~1', '/').gsub('~0', '~') }
                   .map { |p| /^(0|[1-9][0-9]*)$/ =~ p ? p.to_i : p }

          begin
            @payload.dig(*path[1..-1])
          rescue NoMethodError # Polyfill for ruby < 2.3
            path[1..-1].inject(@payload) { |a, p| a[p] }
          end
        end

        def resolve_ri(ri, res_identifiers)
          ri['pointer'] ? res_identifiers[ri['pointer']] : ri
        end

        def resolve_resource(res, res_identifiers)
          return res unless res['relationships']

          res.dup.tap do |resolved_res|
            resolved_res['relationships'] =
              resolve_relationships(res['relationships'], res_identifiers)
          end
        end

        def resolve_relationships(rels, res_identifiers)
          resolved_rels = rels.map do |k, v|
            data =
              if v['data'].is_a?(Array)
                v['data'].map { |ri| resolve_ri(ri, res_identifiers) }
              else
                resolve_ri(v['data'], res_identifiers)
              end
            [k, { 'data' => data }]
          end

          resolved_rels.to_h
        end

        def sort_resources
          @sorted_resources = []
          @state = {}
          return if @payload['data'].nil?
          _sort_resources(@payload['data'], '/data')
        end

        def _sort_resources(resource, pointer)
          return if @state[pointer] == :visited
          raise 'Cycle detected' if @state[pointer] == :open
          @state[pointer] = :open

          (resource['relationships'] || {}).each do |_, v|
            data = v['data'].is_a?(Array) ? v['data'] : [v['data']]
            data.each do |ri|
              next unless ri['pointer']
              _sort_resources(_resource(ri['pointer']), ri['pointer'])
            end
          end

          @state[pointer] = :visited
          @sorted_resources << [resource, pointer]
        end
      end
    end
  end
end
