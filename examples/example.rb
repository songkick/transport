$VERBOSE = nil

dir = File.dirname(__FILE__)
require 'rubygems'
require dir + '/../lib/songkick/transport'
require dir + '/server'

Client = Songkick::Transport::Curb

client = Client.new('http://localhost:4567',
                    :user_agent => 'Test Client v1.0',
                    :timeout    => 1)

100.times { client.get('/') }

p [:result, client.get('/')]
p [:result, (client.get('/slow') rescue nil)]
p [:result, (client.get('/bad') rescue nil)]

client = Client.new('http://nosuchhost:8000')
p [:result, (client.get('/') rescue nil)]

=begin

OUTPUT:

[:result, #<Songkick::Transport::Response::OK:0x7fe2222a69d8 @data={"hello"=>"world"}>]

E, [2011-11-24T12:11:46.062361 #12123] ERROR : Request timed out: get http://localhost:4567/slow {}
[:result, nil]

E, [2011-11-24T12:11:46.065107 #12123] ERROR : Request returned invalid JSON: get http://localhost:4567/bad {}
[:result, nil]

E, [2011-11-24T12:11:46.066772 #12123] ERROR : Could not connect to host: http://nosuchhost:8000
[:result, nil]

=end
