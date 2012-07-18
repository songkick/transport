module Songkick
  module Transport
    
    class Headers
      include Enumerable
      
      def initialize(hash = {})
        @hash = {}
        hash.each do |key, value|
          @hash[self.class.normalize(key)] = value
        end
      end
      
      def each(&block)
        @hash.each(&block)
      end
      
      def [](header_name)
        @hash[self.class.normalize(header_name)]
      end
      
      def self.normalize(header_name)
        header_name.
            gsub(/^HTTP_/, '').gsub('_', '-').
            downcase.
            gsub(/(^|-)([a-z])/) { $1 + $2.upcase }
      end
    end
    
  end
end

