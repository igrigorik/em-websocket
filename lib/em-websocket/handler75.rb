module EventMachine
  module WebSocket
    class Handler75 < Handler
      def handshake
        location  = "#{@request['Host'].scheme}://#{@request['Host'].host}"
        location << ":#{@request['Host'].port}" if @request['Host'].port
        location << @request['Path']

        upgrade =  "HTTP/1.1 101 Web Socket Protocol Handshake\r\n"
        upgrade << "Upgrade: WebSocket\r\n"
        upgrade << "Connection: Upgrade\r\n"
        upgrade << "WebSocket-Origin: #{@request['Origin']}\r\n"
        upgrade << "WebSocket-Location: #{location}\r\n\r\n"

        debug [:upgrade_headers, upgrade]

        return upgrade
      end
    end
  end
end
