module Songkick
  module Transport
    
    class Base
      attr_accessor :user_agent
      
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
      
    private
      
      def process(url, status, headers, body)
        Response.process(url, status, headers, body)
      end
      
      def headers
        Headers.new(
          'Connection' => 'close',
          'User-Agent' => user_agent || ''
        )
      end
      
      def logger
        Transport.logger
      end
    end
    
  end
end

