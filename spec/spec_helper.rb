require 'rubygems'
require File.expand_path('../../lib/songkick/transport', __FILE__)

require 'logger'
require 'sinatra'
require 'thin'

Thin::Logging.silent = true
Songkick::Transport.logger = Logger.new(StringIO.new)
#RSpec.configure { |config| config.raise_errors_for_deprecations! }

class TestApp < Sinatra::Base
  before do
    headers 'Content-Type' => 'application/json'
  end

  get('/')  { Yajl::Encoder.encode(params) }
  post('/') { Yajl::Encoder.encode(params) }

  get '/invalid' do
    '}'
  end

  get '/authenticate' do
    env['HTTP_AUTHORIZATION'] ?
        Yajl::Encoder.encode('successful' => true) :
        Yajl::Encoder.encode('successful' => false)
  end

  get '/artists/:id' do
    Yajl::Encoder.encode('id' => params[:id].to_i)
  end

  options '/.well-known/host-meta' do
    headers 'Access-Control-Allow-Methods' => 'GET, PUT, DELETE'
    ''
  end

  post '/artists' do
    Yajl::Encoder.encode('id' => 'new', 'name' => params[:name].upcase)
  end

  post '/content' do
    Yajl::Encoder.encode('type' => env['CONTENT_TYPE'])
  end

  put '/artists/:id' do
    name = params[:name] || CGI.parse(env['rack.input'].read)['name'].first || ''
    Yajl::Encoder.encode('id' => params[:id].to_i, 'name' => name.downcase)
  end

  post '/process' do
    Yajl::Encoder.encode('body' => request.body.read, 'type' => request.env['CONTENT_TYPE'])
  end

  %w[post put].each do |verb|
    __send__(verb, '/upload') do
      begin
      c = params[:concert]
      Yajl::Encoder.encode(
        "filename" => c[:file][:filename],
        "method"   => verb,
        "size"     => c[:file][:tempfile].size,
        "foo"      => c[:foo]
      )
      rescue => e
        p e
      end
    end
  end

  def self.ensure_reactor_running
    Thread.new { EM.run } unless EM.reactor_running?
    Thread.pass until EM.reactor_running?
  end

  def self.listen(port)
    ensure_reactor_running
    thin = Rack::Handler.get('thin')
    app  = Rack::Lint.new(self)
    thin.run(app, :Port => port) { |s| @server = s }
  end

  def self.stop
    @server.stop
    sleep 1
  end
end

class FakeCurl
  attr_writer :url, :timeout
  attr_reader :on_header, :response_code, :body_str, :headers

  def initialize(options = {})
    @error = options[:error]
    @headers = {}
  end

  def http(verb)
    raise(@error, "bang") if @error
  end

  def reset
  end
end

