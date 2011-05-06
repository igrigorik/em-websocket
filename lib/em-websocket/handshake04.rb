require 'digest/sha1'
require 'base64'

module EventMachine
  module WebSocket
    module Handshake04
      def handshake
        # Required
        unless key = request['sec-websocket-key']
          raise HandshakeError, "Sec-WebSocket-Key header is required"
        end
        
        # Optional
        origin = request['sec-websocket-origin']
        protocols = request['sec-websocket-protocol']
        extensions = request['sec-websocket-extensions']
        
        string_to_sign = "#{key}258EAFA5-E914-47DA-95CA-C5AB0DC85B11"
        signature = Base64.encode64(Digest::SHA1.digest(string_to_sign)).chomp
        
        upgrade = ["HTTP/1.1 101 Switching Protocols"]
        upgrade << "Upgrade: websocket"
        upgrade << "Connection: Upgrade"
        upgrade << "Sec-WebSocket-Accept: #{signature}"
        
        # TODO: Support Sec-WebSocket-Protocol
        # TODO: Sec-WebSocket-Extensions
        
        debug [:upgrade_headers, upgrade]
        
        return upgrade.join("\r\n") + "\r\n\r\n"
      end
    end
  end
end
