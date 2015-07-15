module Songkick
  module Transport
    class HttpError < UpstreamError
      attr_reader :request, :data, :headers, :status

      def initialize(request, status, headers, body)
        @request = request

        @data = if body.is_a?(String)
                  body.strip == '' ? nil : (JSON.parse(body) rescue body)
                else
                  body
                end

        @headers = Headers.new(headers)
        @status  = status.to_i
      end

      def message
       "#{self.class}: status code: #{@status} from: #{@request}"
      end
    end
  end
end
