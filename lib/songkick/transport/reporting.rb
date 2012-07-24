module Songkick
  module Transport
    
    module Reporting
      def self.report
        Report.new
      end
      
      def self.record(*args)
        return unless report = Thread.current[:songkick_transport_report]
        report.record(*args)
      end
      
      def self.log_request(request)
        return unless Transport.verbose?
        logger.info(request.to_s)
      end
      
      def self.log_response(response, request)
        return unless Transport.verbose?
        duration = (Time.now.to_f - request.start_time.to_f) * 1000
        logger.info "Response status: #{response.status}, duration: #{duration.ceil}ms"
        logger.debug "Response data: #{response.data.inspect}"
      end
      
      def self.logger
        Transport.logger
      end
      
      class Report
        include Enumerable
        extend Forwardable
        def_delegators :@requests, :each, :first, :last, :length, :size, :[]
        
        def initialize
          @requests = []
        end
        
        def execute
          Thread.current[:songkick_transport_report] = self
          yield
        ensure
          Thread.current[:songkick_transport_report] = nil
        end
        
        def record(*args)
          @requests << Request.new(*args)
        end
        
        def total_duration
          inject(0) { |s,r| s + r.duration }
        end
      end
    end
    
  end
end

