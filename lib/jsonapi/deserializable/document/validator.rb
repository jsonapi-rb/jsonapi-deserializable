module JSONAPI
  module Deserializable
    class Document
      class Validator
        def initialize(document)
          @document = document
        end

        def validate(wl, &block)
          catch(:error) do
            unless @document.payload['data'].nil? ||
                   @document.payload['data'].is_a?(Hash)
              yield('Expected one primary resource', '/data')
              throw :error
            end

            _whitelist_one(wl, @document.payload['data'], '/data', &block)
          end
        end

        private

        def _whitelist_one(wl, data, pointer, &block)
          return if data.nil?

          unless data.is_a?(Hash)
            yield('Expected to-one relationship', pointer)
            throw :error
          end

          if data['pointer']
            if wl[:pointers]
              pointer = data['pointer']
              data = @document.resource(data['pointer'])
            else
              yield('Unauthorized pointer', pointer)
              throw :error
            end
          end

          if wl[:types] && !wl[:types].include?(data['type'].to_sym)
            yield("Unauthorized type #{data['type']}", pointer + '/type')
          end

          (data['relationships'] || {}).each do |k, v|
            rel_pointer = pointer + '/relationships/' + k + '/data'
            if (rel_wl = (wl[:one] || {})[k.to_sym])
              _whitelist_one(rel_wl, v['data'], rel_pointer, &block)
            elsif (rel_wl = (wl[:many] || {})[k.to_sym])
              _whitelist_many(rel_wl, v['data'], rel_pointer, &block)
            else
              yield('Unauthorized relationship', rel_pointer)
              throw :error
            end
          end
        end

        def _whitelist_many(wl, data, pointer, &block)
          unless data.is_a?(Array)
            yield('Expected to-many relationship', pointer)
            throw :error
          end

          data.each_with_index do |res, ind|
            _whitelist_one(wl, res, "#{pointer}/#{ind}", &block)
          end
        end
      end
    end
  end
end
