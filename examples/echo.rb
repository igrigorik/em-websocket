require File.expand_path('../../lib/em-websocket', __FILE__)

EM.run {
  EM::WebSocket.run(:host => "0.0.0.0", :port => 8080, :debug => false) do |ws|
    ws.onopen { |handshake, connection|
      puts "WebSocket opened #{{
        :path => handshake.path,
        :query => handshake.query,
        :origin => handshake.origin,
      }}"
      puts "from #{connection.remote_addr}"

      ws.send "Hello Client!"
    }
    ws.onmessage { |msg|
      ws.send "Pong: #{msg}"
    }
    ws.onclose {
      puts "WebSocket closed"
    }
    ws.onerror { |e|
      puts "Error: #{e.message}"
    }
  end
}
