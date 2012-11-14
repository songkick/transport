require 'cgi'
require 'curb'

module Songkick
  module Transport

    class Curb < Base
      # Send this so that curb will not implement Section 8.2.3 of RFC 2616,
      # which our Ruby HTTP servers are not equipped to respond to. (If not
      # sent it causes an additional 1s of latency for all requests with post
      # data longer than 1k)
      DEFAULT_HEADERS = {"Expect" => ""}

      def self.clear_thread_connection
         Thread.current[:transport_curb_easy] = nil
      end
      
      def initialize(host, options = {})
        @host       = host
        @timeout    = options[:timeout] || DEFAULT_TIMEOUT
        @user_agent = options[:user_agent]
        if c = options[:connection]
          Thread.current[:transport_curb_easy] = c
        end
      end
      
      def connection
        Thread.current[:transport_curb_easy] ||= Curl::Easy.new
      end
      
      def endpoint
        @host
      end
      
      def execute_request(req)
        connection.reset
        
        connection.url = req.url
        connection.timeout = req.timeout || @timeout
        connection.headers.update(DEFAULT_HEADERS.merge(req.headers))
        
        response_headers = {}
        
        connection.on_header do |header_line|
          line = header_line.sub(/\r\n$/, '')
          parts = line.split(/:\s*/)
          if parts.size >= 2
            response_headers[parts.shift] = parts * ':'
          end
          header_line.bytesize
        end
        
        if req.use_body?
          connection.__send__("http_#{req.verb}", req.body)
        else
          connection.__send__("http_#{req.verb}")
        end

        process(req, connection.response_code, response_headers, connection.body_str)

      rescue Curl::Err::HostResolutionError => error
        logger.warn "Could not resolve host: #{@host}"
        raise Transport::HostResolutionError, req

      rescue Curl::Err::ConnectionFailedError => error
        logger.warn "Could not connect to host: #{@host}"
        raise Transport::ConnectionFailedError, req

      rescue Curl::Err::TimeoutError => error
        logger.warn "Request timed out after #{@timeout}s : #{req}"
        raise Transport::TimeoutError, req

      rescue Curl::Err::GotNothingError => error
        logger.warn "Got nothing: #{req}"
        raise Transport::UpstreamError, req
      end
    end

  end
end

