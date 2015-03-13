module Songkick
  module Transport

    class TimeoutDecorator
      def initialize(client, timeout)
        @client  = client
        @timeout = timeout
      end

      HTTP_VERBS.each do |verb|
        class_eval %{
          def #{verb}(path, params = {}, headers ={}, timeout = nil)
            @client.__send__(:#{verb}, path, params, headers, timeout || @timeout)
          end
        }
      end

      def with_headers(headers = {})
        HeaderDecorator.new(self, @headers.merge(headers))
      end

      private

      def method_missing(*args, &block)
        @client.__send__(*args, &block)
      end
    end

  end
end

