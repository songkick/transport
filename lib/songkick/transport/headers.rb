module Songkick
  module Transport

    class Headers
      include Enumerable

      def self.new(hash)
        return hash if self === hash
        super
      end

      def self.normalize(header_name)
        header_name.
            gsub(/^HTTP_/, '').gsub('_', '-').
            downcase.
            gsub(/(^|-)([a-z])/) { $1 + $2.upcase }
      end

      def initialize(hash = {})
        @hash = {}
        hash.each do |key, value|
          next if value.nil?
          @hash[self.class.normalize(key)] = value
        end
      end

      def each(&block)
        @hash.each(&block)
      end

      def [](header_name)
        @hash[self.class.normalize(header_name)]
      end

      def []=(header_name, value)
        @hash[self.class.normalize(header_name)] = value
      end

      def merge(hash)
        headers = self.class.new(to_hash)
        hash.each { |k,v| headers[k] = v }
        headers
      end

      def to_hash
        @hash.dup
      end

      def ==(other)
        to_hash == other.to_hash
      end
    end

  end
end

