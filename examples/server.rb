require 'rubygems'
require 'sinatra'

get '/' do
  '{"hello":"world"}'
end

get '/slow' do
  sleep 60
  '{"helloooooo":"world"}'
end

get '/bad' do
  '"hello":"world"'
end
