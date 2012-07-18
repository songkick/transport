$VERBOSE = nil

dir = File.dirname(__FILE__)
require 'rubygems'
require dir + '/../lib/songkick/transport'
require 'eventmachine'

Client = Songkick::Transport::Curb

client = Client.new('http://localhost:4567',
                    :user_agent => 'Test Client v1.0',
                    :timeout    => 1)

EM.run {
  EM.add_periodic_timer(5) { p client.get('/') }
}

