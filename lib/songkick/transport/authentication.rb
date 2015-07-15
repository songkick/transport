require "base64"

module Songkick
  module Transport
    module Authentication
      
      extend self
      
      def basic_auth_headers(credentials)
        username = credentials.fetch(:username)
        password = credentials.fetch(:password)
        encoded_creds = strict_encode64("#{username}:#{password}")
        Headers.new({"Authorization" => "Basic #{encoded_creds}"})
      end

      # Base64.strict_encode64 is not available on Ruby 1.8.7
      def strict_encode64(str)
        Base64.encode64(str).gsub("\n", '')
      end
    
    end
  end
end
