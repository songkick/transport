module Songkick
  module Transport

    class Base
      attr_accessor :user_agent, :user_error_codes

      module API
        def get(path, params = {}, head = {}, timeout = nil)
          do_verb("get", path, params, head, timeout)
        end

        def post(path, params = {}, head = {}, timeout = nil)
          do_verb("post", path, params, head, timeout)
        end

        def put(path, params = {}, head = {}, timeout = nil)
          do_verb("put", path, params, head, timeout)
        end

        def patch(path, params = {}, head = {}, timeout = nil)
          do_verb("patch", path, params, head, timeout)
        end

        def delete(path, params = {}, head = {}, timeout = nil)
          do_verb("delete", path, params, head, timeout)
        end

        def options(path, params = {}, head = {}, timeout = nil)
          do_verb("options", path, params, head, timeout)
        end

        def head(path, params = {}, head = {}, timeout = nil)
          do_verb("head", path, params, head, timeout)
        end

        def with_headers(headers = {})
          HeaderDecorator.new(self, headers)
        end

        def with_timeout(timeout = DEFAULT_TIMEOUT)
          TimeoutDecorator.new(self, timeout)
        end
      end

      include API

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

      class HeaderDecorator < Struct.new(:client, :headers)
        include API

        def do_verb(verb, path, params = {}, new_headers = {}, timeout = nil)
          client.do_verb(verb, path, params, Headers.new(headers).merge(new_headers), timeout)
        end

        def method_missing(*args, &block)
          client.__send__(*args, &block)
        end
      end

      class TimeoutDecorator < Struct.new(:client, :timeout)
        include API

        def do_verb(verb, path, params = {}, headers = {}, new_timeout = nil)
          client.do_verb(verb, path, params, headers, new_timeout || timeout)
        end

        def method_missing(*args, &block)
          client.__send__(*args, &block)
        end
      end
    end
  end
end

