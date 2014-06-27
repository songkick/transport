require 'rack/test'
require 'timeout'

module Songkick
  module Transport
    
    class RackTest < Base
      class Client
        attr_reader :app
        include Rack::Test::Methods
        
        def initialize(app)
          @app = app
        end
      end
      
      def initialize(app, options = {})
        @app     = app
        @timeout = options[:timeout] || DEFAULT_TIMEOUT
        @user_error_codes = options[:user_error_codes] || DEFAULT_USER_ERROR_CODES
      end
      
      HTTP_VERBS.each do |verb|
        class_eval %{
          def #{verb}(path, params = {}, head = {}, timeout = nil)
            client  = Client.new(@app)
            start   = Time.now
            request = Request.new(@app, '#{verb}', path, params, headers.merge(head), timeout)
            result  = nil
            
            Timeout.timeout(timeout || @timeout) do
              request.headers.each { |key, value| client.header(key, value) }
              response = client.#{verb}(path, params)
              request.response = process("\#{path}, \#{params.inspect}", response.status, response.headers, response.body)
              Reporting.record(request)
              request.response
            end

          rescue UpstreamError => error
            request.error = error
            Reporting.record(request)
            raise error
          
          rescue Object => error
            logger.warn(error.message)
            raise UpstreamError, request
          end
        }
      end
    end
    
  end
end

