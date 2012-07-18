require 'rack/test'
require 'timeout'

module Songkick
  module Transport
    
    class RackTest < Base
      include Rack::Test::Methods
      attr_reader :app
      
      def initialize(app, options = {})
        @app     = app
        @timeout = options[:timeout] || DEFAULT_TIMEOUT
      end
      
      HTTP_VERBS.each do |verb|
        class_eval %{
          def #{verb}(path, params = {})
            start = Time.now
            result = nil
            
            Timeout.timeout(@timeout) do
              response = super
              result = process("\#{path}, \#{params.inspect}", response.status, response.headers, response.body)
              Reporting.record(@app, "#{verb}", path, params, start, result)
              result
            end

          rescue UpstreamError => error
            Reporting.record(@app, "#{verb}", path, params, start, nil, error)
            raise error
          
          rescue Object => error
            logger.warn(error.message)
            raise UpstreamError, Request.new(@app, "#{verb}", path, params)
          end
        }
      end
    end
    
  end
end

