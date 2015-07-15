require 'rubygems'
require File.expand_path('../../lib/songkick/transport', __FILE__)

require 'active_support/notifications'
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

  get('/')  { JSON.generate(params) }
  post('/') { JSON.generate(params) }

  not_found do
    halt 404, '{"error": "not found"}'
  end

  get '/invalid' do
    '}'
  end

  get '/authenticate' do
    env['HTTP_AUTHORIZATION'] ?
        JSON.generate('successful' => true) :
        JSON.generate('successful' => false)
  end

  get '/artists/:id' do
    JSON.generate('id' => params[:id].to_i)
  end

  options '/.well-known/host-meta' do
    headers 'Access-Control-Allow-Methods' => 'GET, PUT, DELETE'
    ''
  end

  post '/artists' do
    JSON.generate('id' => 'new', 'name' => params[:name].upcase)
  end

  post '/content' do
    JSON.generate('type' => env['CONTENT_TYPE'])
  end

  put '/artists/:id' do
    name = params[:name] || CGI.parse(env['rack.input'].read)['name'].first || ''
    JSON.generate('id' => params[:id].to_i, 'name' => name.downcase)
  end

  post '/process' do
    JSON.generate('body' => request.body.read, 'type' => request.env['CONTENT_TYPE'])
  end

  %w[post put].each do |verb|
    __send__(verb, '/upload') do
      begin
      c = params[:concert]
      JSON.generate(
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
