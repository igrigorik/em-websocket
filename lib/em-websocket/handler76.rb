require 'digest/md5'

module EventMachine
  module WebSocket
    class Handler76 < Handler
      # "\377\000" is octet version and "\xff\x00" is hex version
      TERMINATE_STRING = "\xff\x00"

      def handshake
        challenge_response = solve_challenge(
          @request['Sec-WebSocket-Key1'],
          @request['Sec-WebSocket-Key2'],
          @request['Third-Key']
        )

        location  = "#{@request['Host'].scheme}://#{@request['Host'].host}"
        location << ":#{@request['Host'].port}" if @request['Host'].port
        location << @request['Path']

        upgrade =  "HTTP/1.1 101 WebSocket Protocol Handshake\r\n"
        upgrade << "Upgrade: WebSocket\r\n"
        upgrade << "Connection: Upgrade\r\n"
        upgrade << "Sec-WebSocket-Location: #{location}\r\n"
        upgrade << "Sec-WebSocket-Origin: #{@request['Origin']}\r\n"
        if protocol = @request['Sec-WebSocket-Protocol']
          validate_protocol!(protocol)
          upgrade << "Sec-WebSocket-Protocol: #{protocol}\r\n"
        end
        upgrade << "\r\n"
        upgrade << challenge_response

        debug [:upgrade_headers, upgrade]

        return upgrade
      end

      private

      def solve_challenge(first, second, third)
        # Refer to 5.2 4-9 of the draft 76
        sum = [(extract_nums(first) / count_spaces(first))].pack("N*") +
          [(extract_nums(second) / count_spaces(second))].pack("N*") +
          third
        Digest::MD5.digest(sum)
      end

      def extract_nums(string)
        string.scan(/[0-9]/).join.to_i
      end

      def count_spaces(string)
        spaces = string.scan(/ /).size
        # As per 5.2.5, abort the connection if spaces are zero.
        raise HandshakeError, "Websocket Key1 or Key2 does not contain spaces - this is a symptom of a cross-protocol attack" if spaces == 0
        return spaces
      end

      def validate_protocol!(protocol)
        raise HandshakeError, "Invalid WebSocket-Protocol: empty" if protocol.empty?
        # TODO: Validate characters
      end
    end
  end
end
