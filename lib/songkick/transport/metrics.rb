module Songkick
  module Transport
    module Metrics
      METRIC_ERRORS = [
        HostResolutionError,
        ConnectionFailedError,
        TimeoutError
      ]

      def self.log(error, req)
        return unless METRIC_ERRORS.include? error.class

        increment_error_counter(error, req)
      end

      private

      def self.increment_error_counter(error, req)
        return unless error_counter
        error_counter.increment(
          labels: {
            error: error.class,
            endpoint: req.endpoint,
            path: req.path,
            verb: req.verb
          }
        )
      end

      def self.error_counter
        @error_counter ||= begin
          return nil unless defined? Prometheus::Client
          registry = Prometheus::Client.registry
          counter = Prometheus::Client::Counter.new(
            :http_errors,
            docstring: 'A counter of HTTP errors',
            labels: [:error, :endpoint, :path, :verb]
          )
          registry.register(counter)
          counter
        end
      end
    end
  end
end
