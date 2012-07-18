$VERBOSE = nil

dir = File.dirname(__FILE__)
require 'rubygems'
require dir + '/../lib/songkick/transport'

Client = Songkick::Transport::Curb

client = Client.new('http://localhost:4567', :timeout => 120)

threads = %w[/ /slow].map do |path|
  Thread.new { p client.get(path) }
end

threads.each { |t| t.join }

