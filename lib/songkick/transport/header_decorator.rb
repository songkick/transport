module Songkick
  module Transport
    
    class HeaderDecorator
      def initialize(client, headers)
        @client  = client
        @headers = headers
      end
      
      HTTP_VERBS.each do |verb|
        class_eval %{
          def #{verb}(path, params = {}, headers ={})
            @client.__send__(:#{verb}, path, params, @headers.merge(headers))
          end
        }
      end
    
    private
      
      def method_missing(*args, &block)
        @client.__send__(*args, &block)
      end
    end
    
  end
end

