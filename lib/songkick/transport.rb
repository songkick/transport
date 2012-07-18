require 'forwardable'
require 'net/http'
require 'net/http/post/multipart'
require 'uri'
require 'yajl'

module Songkick
  module Transport
    DEFAULT_TIMEOUT = 5
    DEFAULT_FORMAT  = :json
    
    HTTP_VERBS = %w[get post put delete head]
    USE_BODY   = %w[post put]
    
    ROOT = File.expand_path('..', __FILE__)
    autoload :Serialization,  ROOT + '/transport/serialization'
    autoload :Curb,           ROOT + '/transport/curb'
    autoload :Headers,        ROOT + '/transport/headers'
    autoload :HttParty,       ROOT + '/transport/httparty'
    autoload :RackTest,       ROOT + '/transport/rack_test'
    autoload :Reporting,      ROOT + '/transport/reporting'
    autoload :Request,        ROOT + '/transport/request'
    autoload :Response,       ROOT + '/transport/response'

    autoload :UpstreamError,        ROOT + '/transport/upstream_error'
    autoload :HostResolutionError,  ROOT + '/transport/upstream_error'
    autoload :TimeoutError,         ROOT + '/transport/upstream_error'
    autoload :ConnectionFailedError,ROOT + '/transport/upstream_error'
    autoload :InvalidJSONError,     ROOT + '/transport/upstream_error'
    autoload :HttpError,            ROOT + '/transport/http_error'
    
    IO = UploadIO
    
    def self.logger
      # temporary measure while migration from janda to gem
      @logger ||= Object.new.extend(Songkick::Diagnostics::HasLogger).logger
    end
    
    def self.logger=(logger)
      @logger = logger
    end
    
    def self.verbose=(verbose)
      @verbose = verbose
    end
    
    def self.verbose?
      @verbose
    end
    
    def self.io(object)
      if Hash === object and [:tempfile, :type, :filename].all? { |k| object.has_key? k } # Rack upload
        Transport::IO.new(object[:tempfile], object[:type], object[:filename])
        
      elsif object.respond_to?(:content_type) and object.respond_to?(:original_filename) # Rails upload
        Transport::IO.new(object, object.content_type, object.original_filename)
        
      else
        raise ArgumentError, "Could not generate a Transport::IO from #{object.inspect}"
      end
    end
    
    def self.report
      Reporting.report
    end
    
    class Base
      attr_accessor :user_agent
      
      HTTP_VERBS.each do |verb|
        class_eval %{
          def #{verb}(path, params = {})
            req = Request.new(endpoint, '#{verb}', path, params)
            Reporting.log_request(req)
            
            response = execute_request(req)
            
            Reporting.log_response(response, req)
            Reporting.record(endpoint, '#{verb}', path, params, req.start_time, response)
            response
          rescue => error
            Reporting.record(endpoint, '#{verb}', path, params, req.start_time, nil, error)
            raise error
          end
        }
      end
      
    private
      
      def process(url, status, headers, body)
        Response.process(url, status, headers, body)
      end
      
      def headers
        {
          'Connection' => 'close',
          'User-Agent' => user_agent || ''
        }
      end
      
      def logger
        Transport.logger
      end
    end
    
  end
end

