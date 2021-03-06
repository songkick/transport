module Songkick
  module Transport
    class Service
      DEFAULT_TIMEOUT = 10
      DEFAULT_TRANSPORT = Songkick::Transport::Curb

      def self.ancestor
        warn "DEPRECATED: calling ancestor on #{self}"
        self.ancestors.select { |a| a.respond_to?(:get_user_agent) }[1]
      end

      def self.stub_transport(stub)
        warn "DEPRECATED: calling stub_transport on #{self}"
        @stub_transport = stub
      end

      def self.extra_headers
        warn "DEPRECATED: calling extra_headers on #{self}"
        get_with_headers
      end

      def self.this_extra_headers
        warn "DEPRECATED: calling this_extra_headers on #{self}"
        @with_headers || {}
      end

      def self.parent_service
        superclass if superclass <= Songkick::Transport::Service
      end
      private_class_method :parent_service

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

      def self.transport_layer_options(value)
        @transport_layer_options = value
      end

      def self.set_endpoints(hash)
        unless self == Songkick::Transport::Service
          raise "set_endpoints only on Songkick::Transport::Service"
        end
        @endpoints = hash
      end

      def self.get_endpoint_name
        @endpoint_name || (parent_service && parent_service.get_endpoint_name) ||
          raise("no endpoint specified for #{self}, call endpoint 'foo' inside #{self}")
      end

      def self.get_endpoint
        Service.get_endpoints[self.get_endpoint_name] ||
          raise("can't find endpoint for '#{self.get_endpoint_name}', should have called Songkick::Transport::Service.set_endpoints")
      end

      def self.get_timeout
        @timeout || (parent_service && parent_service.get_timeout) || DEFAULT_TIMEOUT
      end

      def self.get_user_agent
        @user_agent || (parent_service && parent_service.get_user_agent)
      end

      def self.get_endpoints
        @endpoints || {}
      end

      def self.get_transport_layer
        @transport_layer || (parent_service && parent_service.get_transport_layer) || DEFAULT_TRANSPORT
      end

      def self.get_transport_layer_options
        ((parent_service && parent_service.get_transport_layer_options) || {}).merge(@transport_layer_options || {})
      end

      def self.get_stub_transport
        @stub_transport || (parent_service && parent_service.get_stub_transport) || nil
      end

      def self.get_with_headers
        ((parent_service && parent_service.get_with_headers) || {}).merge(@with_headers || {})
      end

      def self.new_transport
        unless user_agent = get_user_agent
          raise "no user agent specified for #{self}, call user_agent 'foo' inside #{self} or on Songkick::Transport::Service"
        end
        get_stub_transport || get_transport_layer.new(self.get_endpoint, { :user_agent => user_agent, :timeout => get_timeout }.merge(get_transport_layer_options))
      end

      def self.with_headers(headers)
        @with_headers = headers
      end

      def http
        r = (@http ||= self.class.new_transport)
        if self.class.get_with_headers.any?
          r.with_headers(self.class.get_with_headers)
        else
          r
        end
      end

      def stub_transport(http)
        @http = http
      end

      def rescue_404(response=nil)
        yield
      rescue Songkick::Transport::HttpError => e
        e.status == 404 ? response : (raise e)
      end

    end
  end
end
