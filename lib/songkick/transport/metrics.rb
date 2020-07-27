module Songkick
  module Transport
    module Metrics
      METRIC_ERRORS = [
        HostResolutionError,
        ConnectionFailedError,
        TimeoutError,
        HttpError
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
            error:          Metrics.error_name(error),
            target_service: Metrics.service_name(req.endpoint),
            path:           Metrics.sanitize_path(req.path),
            verb:           req.verb
          }
        )
      end

      def self.error_counter
        @error_counter ||= begin
          return nil unless defined? Songkick::Instruments
          counter = Songkick::Instruments.counter(
            :transport_errors,
            docstring: 'A counter of HTTP errors',
            labels: [:error, :target_service, :path, :verb]
          )
          counter
        end
      end

      def self.service_name(endpoint)
        Service.get_endpoints.key(endpoint) || endpoint
      end

      def self.sanitize_path(path)
        path_array = path.sub(/^\//, '').split('/')
        path_array.map! do |part|
          part.gsub(/\d+/, '_id')
        end
        path_array.join('.')
      end

      def self.error_name(error)
        error.class.name.split('::').last
      end
    end
  end
end
