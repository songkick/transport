module Songkick
  module Transport
    module Serialization

      extend self

      SANITIZED_VALUE = '[REMOVED]'

      def build_url(verb, host, path, params, scrub=false)
        url = host + path
        return url if USE_BODY.include?(verb)
        qs  = build_query_string(params, true, scrub)
        url + (qs == '' ? '' : '?' + qs)
      end

      def build_query_string(params, fully_encode = true, sanitize = false)
        return params if String === params
        pairs = []
        each_qs_param('', params, fully_encode) do |key, value|
          value = SANITIZED_VALUE if sanitize and sanitize?(key)
          pairs << [key, value]
        end
        if fully_encode
          pairs.map { |p| p.join('=') }.join('&')
        else
          pairs.inject({}) do |hash, pair|
            hash[pair.first] = pair.last
            hash
          end
        end
      end

      def each_qs_param(prefix, value, fully_encode = true, &block)
        case value
        when Array
          value.each { |e| each_qs_param(prefix + "[]", e, fully_encode, &block) }
        when Hash
          value.each do |k,v|
            encoded = fully_encode ? CGI.escape(k.to_s) : k.to_s
            key = (prefix == '') ? encoded : prefix + "[#{encoded}]"
            each_qs_param(key, v, fully_encode, &block)
          end
        when Transport::IO
          block.call(prefix, value)
        else
          encoded = fully_encode ? CGI.escape(value.to_s) : value.to_s
          block.call(prefix, encoded)
        end
      end

      def multipart?(params)
        case params
        when Hash  then params.any? { |k,v| multipart? v }
        when Array then params.any? { |e|   multipart? e }
        else Transport::IO === params
        end
      end

      def sanitize?(key)
        Transport.sanitized_params.any? { |param| param === key }
      end

      def serialize_multipart(params, boundary = Multipartable::DEFAULT_BOUNDARY)
        params = build_query_string(params, false)

        parts = params.map { |k,v| Parts::Part.new(boundary, k, v) }
        parts << Parts::EpiloguePart.new(boundary)
        ios = parts.map { |p| p.to_io }

        {
          :content_type   => "multipart/form-data; boundary=#{boundary}",
          :content_length => parts.inject(0) { |sum,i| sum + i.length }.to_s,
          :body           => CompositeReadIO.new(*ios).read
        }
      end

    end
  end
end

