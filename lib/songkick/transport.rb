require 'forwardable'
require 'net/http'
require 'net/http/post/multipart'
require 'uri'
require 'json'

module Songkick
  module Transport
    DEFAULT_TIMEOUT = 5
    DEFAULT_FORMAT  = :json
    DEFAULT_USER_ERROR_CODES = [409]

    HTTP_VERBS    = %w[options head get patch post put delete]
    USE_BODY      = %w[post put]
    FORM_ENCODING = 'application/x-www-form-urlencoded'

    ROOT = File.expand_path('..', __FILE__)

    autoload :Serialization,    ROOT + '/transport/serialization'
    autoload :Base,             ROOT + '/transport/base'
    autoload :Curb,             ROOT + '/transport/curb'
    autoload :Headers,          ROOT + '/transport/headers'
    autoload :HttParty,         ROOT + '/transport/httparty'
    autoload :RackTest,         ROOT + '/transport/rack_test'
    autoload :Reporting,        ROOT + '/transport/reporting'
    autoload :Request,          ROOT + '/transport/request'
    autoload :Response,         ROOT + '/transport/response'
    autoload :Service,          ROOT + '/transport/service'

    autoload :UpstreamError,         ROOT + '/transport/upstream_error'
    autoload :HostResolutionError,   ROOT + '/transport/upstream_error'
    autoload :TimeoutError,          ROOT + '/transport/upstream_error'
    autoload :ConnectionFailedError, ROOT + '/transport/upstream_error'
    autoload :InvalidJSONError,      ROOT + '/transport/upstream_error'
    autoload :HttpError,             ROOT + '/transport/http_error'

    def self.register_parser(content_type, parser)
      @parsers ||= {}
      @parsers[content_type] = parser
    end

    def self.register_default_parser(parser)
      @default_parser = parser
    end

    def self.parser_for(content_type)
      parser = (@parsers && @parsers[content_type]) || @default_parser
      unless parser
        raise TypeError, "Could not find a parser for content-type: #{content_type}"
      end
      parser
    end

    register_parser 'application/json', JSON

    IO = UploadIO

    def self.io(object)
      if Hash === object and [:tempfile, :type, :filename].all? { |k| object.has_key? k } # Rack upload
        Transport::IO.new(object[:tempfile], object[:type], object[:filename])

      elsif object.respond_to?(:content_type) and object.respond_to?(:original_filename) # Rails upload
        Transport::IO.new(object, object.content_type, object.original_filename)

      else
        raise ArgumentError, "Could not generate a Transport::IO from #{object.inspect}"
      end
    end

    def self.logger
      @logger ||= begin
                    require 'logger'
                    Logger.new(STDOUT)
                  end
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

    def self.report
      Reporting.report
    end

    def self.sanitize(*params)
      sanitized_params.concat(params)
    end

    def self.sanitized_params
      @sanitized_params ||= []
    end

  end
end
