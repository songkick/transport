module Songkick
  module Transport

    class HeaderDecorator
      def initialize(client, headers)
        @client  = client
        @headers = Headers.new(headers)
      end

      HTTP_VERBS.each do |verb|
        class_eval %{
          def #{verb}(path, params = {}, headers = {}, timeout = nil)
            @client.__send__(:#{verb}, path, params, @headers.merge(headers), timeout)
          end
        }
      end

      def with_headers(headers = {})
        HeaderDecorator.new(self, @headers.merge(headers))
      end

      def with_timeout(timeout)
        TimeoutDecorator.new(self, timeout)
      end

      private

      def method_missing(*args, &block)
        @client.__send__(*args, &block)
      end
    end

  end
end

