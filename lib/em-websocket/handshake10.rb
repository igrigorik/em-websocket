require 'digest/sha1'

module EventMachine
  module WebSocket
    module Handshake10
      def handshake
        accept_response = solve_challenge(request['sec-websocket-key'])

        upgrade =  "HTTP/1.1 101 WebSocket Protocol Handshake\r\n"
        upgrade << "Upgrade: WebSocket\r\n"
        upgrade << "Connection: Upgrade\r\n"
        upgrade << "Sec-WebSocket-Accept: #{accept_response}\r\n"
        if protocol = request['sec-websocket-protocol']
          validate_protocol!(protocol)
          upgrade << "Sec-WebSocket-Protocol: #{protocol}\r\n"
        end
        upgrade << "\r\n"

        debug [:upgrade_headers, upgrade]

        return upgrade
      end

      private

      def solve_challenge(key)
        Base64.encode64(Digest::SHA1.digest("#{key}258EAFA5-E914-47DA-95CA-C5AB0DC85B11")).strip
      end

      def validate_protocol!(protocol)
        raise HandshakeError, "Invalid WebSocket-Protocol: empty" if protocol.empty?
        # TODO: Validate characters
      end
    end
  end
end
