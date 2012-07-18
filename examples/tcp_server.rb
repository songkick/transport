require 'rubygems'
require 'eventmachine'

module Connection
  HEAD =  "HTTP/1.1 200 OK\r\n" +
          "Content-Type: application/json;charset=utf-8\r\n" +
          "Connection: keep-alive\r\n"
  
  def receive_data(data)
    case data
    when /slow/
      EM.add_timer(60) do
        send_data HEAD +
                  "Content-Length: 17\r\n\r\n" +
                  "{\"hello\":\"world\"}"
      end
    when /bad/
      send_data HEAD +
                "Content-Length: 16\r\n\r\n" +
                "{\"hello\":\"world\""
    
    else
      send_data HEAD +
                "Content-Length: 17\r\n\r\n" +
                "{\"hello\":\"world\"}"
    end
  end
  
  def unbind
    p :connection_closed
  end
end

EM.run {
  EM.start_server('0.0.0.0', 4567, Connection) do |conn|
    p :new_connection
    
    # Close the TCP connection to make sure keep-alive clients reconnect
    EM.add_timer(15) { conn.close_connection_after_writing }
  end
}

