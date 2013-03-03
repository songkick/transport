module Songkick
  module Transport
    
    class Base
      attr_accessor :user_agent, :error_status_codes
      
      HTTP_VERBS.each do |verb|
        class_eval %{
          def #{verb}(path, params = {}, head = {}, timeout = nil)
            req = Request.new(endpoint, '#{verb}', path, params, headers.merge(head), timeout)
            Reporting.log_request(req)
            
            req.response = execute_request(req)
            
            Reporting.log_response(req)
            Reporting.record(req)
            req.response
            
          rescue => error
            req.error = error
            Reporting.record(req)
            raise error
          end
        }
      end
      
      def with_headers(headers = {})
        HeaderDecorator.new(self, headers)
      end
      
      def with_timeout(timeout = DEFAULT_TIMEOUT)
        TimeoutDecorator.new(self, timeout)
      end
      
      # Sets those HTTP Error Status Codes which we expect to yield response 
      # objects with error details, rather than raising an exception.
      #
      # Provide these codes as an argument when initializing the client;
      #
      # client = Transport.new('http://localhost:4567',
      #                        :error_status_codes => [409, 422])
      #                       
      # Defaults to [409] if not provided
      def set_error_status_codes_from(options)
        codes = options[:error_status_codes] || DEFAULT_ERROR_STATUS_CODES
        @error_status_codes = codes
      end
            
    private
      
      def process(url, status, headers, body)
        Response.process(url, status, headers, body, @error_status_codes)
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

