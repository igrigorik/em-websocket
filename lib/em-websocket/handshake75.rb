module EventMachine
  module WebSocket
    module Handshake75
      def handshake
        location  = "#{request['host'].scheme}://#{request['host'].host}"
        location << ":#{request['host'].port}" if request['host'].port
        location << request['path']

        upgrade =  "HTTP/1.1 101 Web Socket Protocol Handshake\r\n"
        upgrade << "Upgrade: WebSocket\r\n"
        upgrade << "Connection: Upgrade\r\n"
        upgrade << "WebSocket-Origin: #{request['origin']}\r\n"
        upgrade << "WebSocket-Location: #{location}\r\n\r\n"

        debug [:upgrade_headers, upgrade]

        return upgrade
      end
    end
  end
end
