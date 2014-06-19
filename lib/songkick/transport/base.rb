module Songkick
  module Transport

    class Base
      attr_accessor :user_agent, :user_error_codes

      HTTP_VERBS.each do |verb|
        class_eval %{
          def #{verb}(path, params = {}, head = {}, timeout = nil)
            do_verb("#{verb}", path, params, head, timeout)
          end
        }
      end

      def do_verb(verb, path, params = {}, head = {}, timeout = nil)
        req = Request.new(endpoint, verb, path, params, headers.merge(head), timeout)
        Reporting.log_request(req)

        begin
          req.response = execute_request(req)
        rescue => error
          req.error = error
          Reporting.record(req)
          raise error
        end

        Reporting.log_response(req)
        Reporting.record(req)
        req.response
      end

      def with_headers(headers = {})
        HeaderDecorator.new(self, headers)
      end

      def with_timeout(timeout = DEFAULT_TIMEOUT)
        TimeoutDecorator.new(self, timeout)
      end

      private

      def process(url, status, headers, body)
        Response.process(url, status, headers, body, @user_error_codes)
      end

      def headers
        Headers.new(
          'Connection' => 'close',
          'User-Agent' => user_agent
        )
      end

      def logger
        Transport.logger
      end
    end

  end
end

