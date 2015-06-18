module Songkick
  module Transport

    class Base
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

        def with_timeout(timeout)
          TimeoutDecorator.new(self, timeout)
        end

        def with_params(params)
          ParamsDecorator.new(self, params)
        end
      end

      include API

      attr_accessor :user_agent, :user_error_codes
      attr_reader :host, :timeout, :instrumenter
      alias_method :endpoint, :host
      DEFAULT_INSTRUMENTATION_LABEL = 'http.songkick_transport'

      def initialize(host, options = {})
        @host       = host
        @timeout    = options[:timeout] || DEFAULT_TIMEOUT
        @user_agent = options[:user_agent]
        @user_error_codes = options[:user_error_codes] || DEFAULT_USER_ERROR_CODES
        @instrumenter ||= options[:instrumenter]
        @instrumentation_label = options[:instrumentation_label] || DEFAULT_INSTRUMENTATION_LABEL
      end

      def do_verb(verb, path, params = {}, head = {}, timeout = nil)
        req = Request.new(endpoint, verb, path, params, headers.merge(head), timeout)
        Reporting.log_request(req)

        instrument(req) do |payload|
          begin
            req.response = execute_request(req)
            payload.merge!({ :status => req.response.status,
                             :response_headers => req.response.headers.to_hash }) if req.response
          rescue => error
            req.error = error
            payload.merge!({ :status => error.status,
                             :response_headers => error.headers.to_hash }) if error.is_a?(HttpError)
            Reporting.record(req)
            raise error
          ensure
            payload.merge!(self.instrumentation_payload_extras)
          end
        end

        Reporting.log_response(req)
        Reporting.record(req)

        req.response
      end

      def instrumentation_payload_extras
        Thread.current[:transport_base_payload_extras] ||= {}
      end

      def instrumentation_payload_extras=(extras)
        Thread.current[:transport_base_payload_extras] = {}
      end

      private

      def process(url, status, headers, body)
        Response.process(url, status, headers, body, @user_error_codes)
      end

      def instrument(request)
        if self.instrumenter
          payload = { :adapter => self.class.name,
                      :endpoint => request.endpoint,
                      :verb => request.verb,
                      :path => request.path,
                      :params => request.params,
                      :request_headers => request.headers.to_hash }

          self.instrumenter.instrument(@instrumentation_label, payload) do
            yield(payload)
          end
        else
          yield({})
        end
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

      class ParamsDecorator < Struct.new(:client, :params)
        include API

        def do_verb(verb, path, new_params = {}, headers = {}, timeout = nil)
          client.do_verb(verb, path, params.merge(new_params), headers, timeout)
        end

        def method_missing(*args, &block)
          client.__send__(*args, &block)
        end
      end
    end
  end
end
