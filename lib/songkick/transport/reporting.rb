require 'erb'

module Songkick
  module Transport

    module Reporting
      def self.start
        Thread.current[:songkick_transport_report] = Report.new
      end

      def self.report
        Thread.current[:songkick_transport_report]
      end

      def self.record(request)
        return unless report
        report << request
      end

      def self.log_request(request)
        return unless Transport.verbose?
        logger.info(request.to_s)
      end

      def self.log_response(request)
        return unless Transport.verbose?
        response = request.response
        duration = (Time.now.to_f - request.start_time.to_f) * 1000
        logger.info "Response status: #{response.status}, duration: #{duration.ceil}ms"
        logger.debug { "Response data: #{response.data.inspect}" }
      end

      def self.logger
        Transport.logger
      end

      class Report
        include Enumerable
        extend Forwardable
        def_delegators :@requests, :each, :first, :last, :length, :size, :[], :<<

        def initialize
          @requests = []
        end

        def execute
          Thread.current[:songkick_transport_report] = self
          yield
        ensure
          Thread.current[:songkick_transport_report] = nil
        end

        def total_duration
          inject(0) { |s,r| s + r.duration }
        end

        # endpoints_to_names is a hash like:
        #
        #   {"dc1-live-service1:9324" => "media-service"}
        def to_html(endpoints_to_names)
          source = File.read(File.expand_path("../html_report.html.erb", __FILE__))
          template = ERB.new(source)
          template.result(binding)
        end
      end
    end

  end
end

