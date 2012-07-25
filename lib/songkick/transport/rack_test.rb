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
      end
      
      HTTP_VERBS.each do |verb|
        class_eval %{
          def #{verb}(path, params = {}, head = {}, timeout = nil)
            client  = Client.new(@app)
            start   = Time.now
            request = Request.new(@app, '#{verb}', path, params, headers.merge(head), timeout, start)
            result  = nil
            
            Timeout.timeout(timeout || @timeout) do
              request.headers.each { |key, value| client.header(key, value) }
              response = client.#{verb}(path, params)
              result = process("\#{path}, \#{params.inspect}", response.status, response.headers, response.body)
              Reporting.record(request, result)
              result
            end

          rescue UpstreamError => error
            Reporting.record(request, nil, error)
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

