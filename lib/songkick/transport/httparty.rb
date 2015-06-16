require 'httparty'

module Songkick
  module Transport

    class HttParty
      def self.new(host, options = {})
        adapter_class = options.delete(:adapter) || Adapter
        adapter_class.base_uri(host)
        adapter_class.format(options[:format] || DEFAULT_FORMAT)
        adapter_class.default_timeout(options[:timeout] || DEFAULT_TIMEOUT)
        adapter_class.new(host, options)
      end

      class Adapter < Base
        include HTTParty

        def endpoint
          self.class.base_uri
        end

        def execute_request(req)
          timeout = req.timeout || self.class.default_options[:timeout]

          response = if req.use_body?
            self.class.__send__(req.verb, req.path, :body => req.body, :headers => req.headers, :timeout => timeout)
          else
            self.class.__send__(req.verb, req.url, :headers => req.headers, :timeout => timeout)
          end

          process(req, response.code, response.headers, response.parsed_response)

        rescue SocketError => error
          logger.warn "Could not connect to host: #{self.class.base_uri}"
          raise ConnectionFailedError, req

        rescue Timeout::Error => error
          logger.warn "Request timed out: #{req}"
          raise Transport::TimeoutError, req

        rescue UpstreamError => error
          raise error

        rescue Object => error
          if error.class.name =~ /json/i or error.message =~ /json/i
            logger.warn("Request returned invalid JSON: #{req}")
            raise Transport::InvalidJSONError, req
          else
            logger.warn("Error trying to call #{req}: #{error.class}: #{error.message}")
            raise UpstreamError, req
          end
        end
      end
    end

  end
end
