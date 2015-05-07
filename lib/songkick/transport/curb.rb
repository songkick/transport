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
        super(host, options)
        @no_signal  = !!options[:no_signal]
        Thread.current[:transport_curb_easy] ||= options[:connection]
      end

      def connection
        Thread.current[:transport_curb_easy] ||= Curl::Easy.new
      end

      def instrumentation_payload_extras
        Thread.current[:transport_curb_payload_extras] ||= {}
      end

      def instrumentation_payload_extras=(extras)
        Thread.current[:transport_curb_payload_extras] = {}
      end

      def execute_request(req)
        self.instrumentation_payload_extras = {} if self.instrumenter
        connection.reset

        connection.url     = req.url
        timeout            = req.timeout || @timeout
        connection.timeout = timeout
        connection.encoding = ''
        connection.headers.update(DEFAULT_HEADERS.merge(req.headers))
        connection.nosignal = true if @no_signal

        response_headers = {}

        connection.on_header do |header_line|
          line = header_line.sub(/\r\n$/, '')
          parts = line.split(/:\s*/)
          if parts.size >= 2
            header_name, value = parts.shift, parts * ':'
            if response_headers[header_name]
              response_headers[header_name] << ", #{value}"
            else
              response_headers[header_name] = value
            end
          end
          header_line.bytesize
        end

        if req.use_body?
          connection.__send__("http_#{req.verb}", req.body)
        else
          connection.http(req.verb.upcase)
        end

        if self.instrumenter
          self.instrumentation_payload_extras[:connect_time] = connection.connect_time
          self.instrumentation_payload_extras[:name_lookup_time] = connection.name_lookup_time
        end

        process(req, connection.response_code, response_headers, connection.body_str)

      rescue Curl::Err::HostResolutionError => error
        logger.warn "Could not resolve host: #{@host}"
        raise Transport::HostResolutionError, req

      rescue Curl::Err::ConnectionFailedError => error
        logger.warn "Could not connect to host: #{@host}"
        raise Transport::ConnectionFailedError, req

      rescue Curl::Err::TimeoutError => error
        logger.warn "Request timed out after #{timeout}s : #{req}"
        raise Transport::TimeoutError, req

      rescue Curl::Err::GotNothingError => error
        logger.warn "Got nothing: #{req}"
        raise Transport::UpstreamError, req

      rescue Curl::Err::RecvError => error
        logger.warn "Failure receiving network data: #{error.message} : #{req}"
        raise Transport::UpstreamError, req

      end
    end

  end
end
