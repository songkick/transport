require "base64"

module Songkick
  module Transport
    module Authorization
      
      extend self
      
      def basic_auth_headers(credentials)
        username = credentials.fetch(:username)
        password = credentials.fetch(:password)
        encoded_creds = Base64.strict_encode64("#{username}:#{password}")
        Headers.new({"Authorization" => "Basic #{encoded_creds}"})
      end
    
    end
  end
end
