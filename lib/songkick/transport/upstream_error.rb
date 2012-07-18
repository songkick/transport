module Songkick
  module Transport
    class UpstreamError < RuntimeError
      attr_reader :request
      
      def initialize(request)
        @request = request
      end
      
      def message
        "#{self.class}: #{@request}"
      end
      alias :to_s :message
    end

    class HostResolutionError < UpstreamError
    end
    
    class ConnectionFailedError < UpstreamError
    end
    
    class TimeoutError < UpstreamError
    end
    
    class InvalidJSONError < UpstreamError
    end
  end
end
