module Songkick
  module Transport
    class Service
      def self.endpoint(name)
        @endpoint_name = name.to_s
      end

      def self.timeout(value)
        @timeout = value
      end

      def self.user_agent(value)
        @user_agent = value
      end

      def self.transport_layer(value)
        @transport_layer = value
      end

      def self.set_endpoints(hash)
        unless self == Songkick::Transport::Service
          raise "set_endpoints only on Songkick::Transport::Service"
        end
        @endpoints = hash
      end

      def self.ancestor
        self.ancestors.select {|a| a.respond_to?(:get_user_agent)}[1]
      end

      def self.get_endpoint_name
        @endpoint_name || (ancestor && ancestor.get_endpoint_name)
      end

      def self.get_timeout
        @timeout || (ancestor && ancestor.get_timeout) || 10
      end

      def self.get_user_agent
        @user_agent || (ancestor && ancestor.get_user_agent)
      end

      def self.get_endpoints
        @endpoints || {}
      end

      def self.get_transport_layer
        @transport_layer || (ancestor && ancestor.get_transport_layer) || Songkick::Transport::Curb
      end

      include Singleton

      def http
        @http ||= begin
          unless name = self.class.get_endpoint_name
            raise "no endpoint specified for #{self.class}, call endpoint 'foo' inside #{self.class}"
          end
          unless endpoint = Service.get_endpoints[name]
            raise "can't find endpoint for '#{name}', should have called Songkick::Transport::Service.set_endpoints"
          end
          unless user_agent = self.class.get_user_agent
            raise "no user agent specified for #{self.class}, call user_agent 'foo' inside #{self.class} or on Songkick::Transport::Service"
          end
          self.class.get_transport_layer.new(endpoint, user_agent: user_agent, 
                                                timeout: self.class.get_timeout)
        end
      end

      def rescue_404(response=nil)
        yield
      rescue Songkick::Transport::HttpError => e
        e.status == 404 ? response : (raise e)
      end

    end
  end
end
