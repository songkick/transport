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
        super(nil, options)
        @app = app
      end

      def endpoint
        @app
      end

      def execute_request(req)
        client = Client.new(@app)

        Timeout.timeout(req.timeout || @timeout) do
          req.headers.each { |key, value| client.header(key, value) }
          response = client.__send__(req.verb, req.path, req.params)
          process(req, response.status, response.headers, response.body)
        end
      end

    end

  end
end
