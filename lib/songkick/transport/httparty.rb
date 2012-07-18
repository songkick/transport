require 'httparty'

module Songkick
  module Transport
    
    class HttParty
      def self.new(host, options = {})
        klass = options[:adapter] || Class.new(Adapter)
        klass.base_uri(host)
        klass.default_timeout(options[:timeout] || DEFAULT_TIMEOUT)
        klass.format(options[:format] || DEFAULT_FORMAT)
        
        transport = klass.new
        transport.user_agent = options[:user_agent]
        transport
      end
      
      class Adapter < Base
        include HTTParty
        
        def endpoint
          self.class.base_uri
        end
        
        def execute_request(req)
          verb, path, params = req.verb, req.path, req.params
          
          response = if req.use_body?
            if req.multipart?
              head = headers.merge('Content-Type'   => req.content_type)
              self.class.__send__(verb, path, :body => req.body, :headers => head)
            else
              self.class.__send__(verb, path, :body => params, :headers => headers)
            end
          else
            self.class.__send__(verb, path, :query => params, :headers => headers)
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

