require 'lib/em-websocket'

EventMachine::WebSocket.start(:host => "0.0.0.0", :port => 8080, :debug => true) do |ws|
  ws.onopen    { ws.send "Hello Client!"}
  ws.onmessage { |msg| ws.send "Pong: #{msg}" }
  ws.onclose   { puts "WebSocket closed" }
end