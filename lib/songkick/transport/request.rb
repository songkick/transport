module Songkick
  module Transport

    class Request
      attr_reader :endpoint,
                  :verb,
                  :path,
                  :params,
                  :timeout,
                  :start_time,
                  :response,
                  :error

      alias :http_method :verb

      def initialize(endpoint, verb, path, params, headers = {}, timeout = DEFAULT_TIMEOUT)
        @endpoint   = endpoint
        @verb       = verb.to_s.downcase
        @path       = path
        @headers    = Headers.new(headers)
        @params     = params
        @timeout    = timeout
        @start_time = start_time || Time.now
        @multipart  = Serialization.multipart?(params)

        if use_body?
          @headers['Content-Type'] ||= @multipart ? multipart_request[:content_type] : FORM_ENCODING
        end
      end

      def response=(response)
        @response = response
        @end_time = Time.now
      end

      def error=(error)
        @error = error
        @end_time = Time.now
      end

      def duration
        return nil unless @end_time
        (@end_time.to_f - @start_time.to_f) * 1000
      end

      def headers
        @headers.to_hash
      end

      def use_body?
        USE_BODY.include?(@verb)
      end

      def multipart?
        @multipart
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

      TRUNCATED_PARAM_LENGTH = 500
      def to_s
        url = String === @endpoint ?
              Serialization.build_url(@verb, @endpoint, @path, @params, true) :
              @endpoint.to_s

        command = "#{@verb.upcase} '#{url}'"
        @headers.each do |key, value|
          value = Serialization::SANITIZED_VALUE if Serialization.sanitize?(key)
          command << " -H '#{key}: #{value}'"
        end
        return command unless use_body?
        sanitized_params = Serialization.build_query_string(params, false, true)
        sanitized_params = sanitized_params.inject({}) do |result, param|
          key, value = param
          if value.length > TRUNCATED_PARAM_LENGTH
            result[key] = "#{value[0...TRUNCATED_PARAM_LENGTH]}[TRUNCATED]"
          else
            result[key] = value
          end
          result
        end
        query = sanitized_params.map { |p| p.join('=') }.join('&')
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
