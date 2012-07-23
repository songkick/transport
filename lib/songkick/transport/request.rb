module Songkick
  module Transport
    
    class Request
      attr_reader :endpoint,
                  :verb,
                  :path,
                  :params,
                  :start_time,
                  :response,
                  :error,
                  :duration
      
      alias :http_method :verb
      
      def initialize(endpoint, verb, path, params, start_time = nil, response = nil, error = nil)
        @endpoint   = endpoint
        @verb       = verb.to_s.downcase
        @path       = path
        @params     = params
        @response   = response
        @error      = error
        @start_time = start_time || Time.now
        @duration   = (Time.now.to_f - start_time.to_f) * 1000
        @multipart  = Serialization.multipart?(params)
      end
      
      def use_body?
        USE_BODY.include?(@verb)
      end
      
      def multipart?
        @multipart
      end
      
      def content_type
        return nil unless use_body?
        if @multipart
          multipart_request[:content_type]
        else
          'application/x-www-form-urlencoded'
        end
      end
      
      def body
        return nil unless use_body?
        if @multipart
          multipart_request[:body]
        else
          Serialization.build_query_string(params)
        end
      end
      
      def url
        Serialization.build_url(@verb, @endpoint, @path, @params)
      end
      
      def to_s
        url = Serialization.build_url(@verb, @endpoint, @path, @params, true)
        command = "#{@verb.upcase} '#{url}'"
        return command unless use_body?
        query = Serialization.build_query_string(params, true, true)
        command << " -H 'Content-Type: #{content_type}'"
        command << " -d '#{query}'"
        command
      end
      
    private
      
      def multipart_request
        return nil unless @multipart
        @multipart_request ||= Serialization.serialize_multipart(params)
      end
    end
    
  end
end

