module Songkick
  module Transport

    class Response
      def self.process(request, status, headers, body)
        case status.to_i
        when 200 then OK.new(status, headers, body)
        when 201 then Created.new(status, headers, body)
        when 204 then NoContent.new(status, headers, body)
        when *UserError.status_codes then UserError.new(status, headers, body)
        else
          Transport.logger.warn "Received error code: #{status} -- #{request}"
          raise HttpError.new(request, status, headers, body)
        end
      rescue Yajl::ParseError
        Transport.logger.warn "Request returned invalid JSON: #{request}"
        raise Transport::InvalidJSONError, request
      end

      attr_reader :data, :headers, :status

      def initialize(status, headers, body)
        @data = if body.is_a?(String)
                  body.strip == '' ? nil : Yajl::Parser.parse(body)
                else
                  body
                end

        @headers = Headers.new(headers)
        @status  = status.to_i
      end

      def errors
        data && data['errors']
      end

      class OK        < Response ; end
      class Created   < Response ; end
      class NoContent < Response ; end

      class UserError < Response
        class << self
          attr_accessor :status_codes
        end

        self.status_codes = [409]
      end
    end

  end
end

