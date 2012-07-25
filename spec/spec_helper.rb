require 'rubygems'
require File.expand_path('../../lib/songkick/transport', __FILE__)

require 'logger'
require 'sinatra'
require 'thin'

Thin::Logging.silent = true
Songkick::Transport.logger = Logger.new(StringIO.new)

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
  
  post '/artists' do
    Yajl::Encoder.encode('id' => 'new', 'name' => params[:name].upcase)
  end
  
  put '/artists/:id' do
    name = params[:name] || CGI.parse(env['rack.input'].read)['name'].first || ''
    Yajl::Encoder.encode('id' => params[:id].to_i, 'name' => name.downcase)
  end
  
  %w[post put].each do |verb|
    __send__(verb, '/upload') do
      c = params[:concert]
      Yajl::Encoder.encode(
        "filename" => c[:file][:filename],
        "method"   => verb,
        "size"     => c[:file][:tempfile].size,
        "foo"      => c[:foo]
      )
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
    sleep 0.1
  rescue
  end
end

