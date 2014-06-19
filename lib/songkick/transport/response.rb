module Songkick
  module Transport
    
    class Response
      def self.process(request, status, headers, body, user_error_codes=409)
        case status.to_i
        when 200 then OK.new(status, headers, body)
        when 201 then Created.new(status, headers, body)
        when 204 then NoContent.new(status, headers, body)
        when *user_error_codes then UserError.new(status, headers, body)
        else
          raise HttpError.new(request, status, headers, body)
        end
      rescue Yajl::ParseError
        Transport.logger.warn "Request returned invalid JSON: #{request}"
        raise Transport::InvalidJSONError, request
      end

      def self.parse(body, content_type)
        return body unless body.is_a?(String)
        return nil if body.strip == ''

        content_type = (content_type || '').split(/\s*;\s*/).first
        Transport.parser_for(content_type).parse(body)
      end
      
      attr_reader :body, :data, :headers, :status
      
      def initialize(status, headers, body)
        @body    = body
        @data    = Response.parse(body, headers['Content-Type'])
        @headers = Headers.new(headers)
        @status  = status.to_i
      end
      
      def errors
        data && data['errors']
      end
    
      class OK        < Response ; end
      class Created   < Response ; end
      class NoContent < Response ; end
      class UserError < Response ; end
    end
    
  end
end

