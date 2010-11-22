module EventMachine
  module WebSocket
    class HandlerFactory
      PATH   = /^(\w+) (\/[^\s]*) HTTP\/1\.1$/
      HEADER = /^([^:]+):\s*(.+)$/

      def self.build(connection, data, secure = false, debug = false)
        (header, remains) = data.split("\r\n\r\n", 2)
        unless remains
          # The whole header has not been received yet.
          return nil
        end

        request = {}

        lines = header.split("\r\n")

        # extract request path
        first_line = lines.shift.match(PATH)
        raise HandshakeError, "Invalid HTTP header" unless first_line
        request['Method'] = first_line[1].strip
        request['Path'] = first_line[2].strip

        unless request["Method"] == "GET"
          raise HandshakeError, "Must be GET request"
        end

        # extract query string values
        request['Query'] = Addressable::URI.parse(request['Path']).query_values ||= {}
        # extract remaining headers
        lines.each do |line|
          h = HEADER.match(line)
          request[h[1].strip] = h[2].strip if h
        end

        version = request['Sec-WebSocket-Key1'] ? 76 : 75
        case version
        when 75
          if !remains.empty?
            raise HandshakeError, "Extra bytes after header"
          end
        when 76
          if remains.length < 8
            # The whole third-key has not been received yet.
            return nil
          elsif remains.length > 8
            raise HandshakeError, "Extra bytes after third key"
          end
          request['Third-Key'] = remains
        else
          raise WebSocketError, "Must not happen"
        end

        unless request['Connection'] == 'Upgrade' and request['Upgrade'] == 'WebSocket'
          raise HandshakeError, "Connection and Upgrade headers required"
        end

        # transform headers
        protocol = (secure ? "wss" : "ws")
        request['Host'] = Addressable::URI.parse("#{protocol}://"+request['Host'])

        if version = request['Sec-WebSocket-Draft']
          if version == '1' || version == '2' || version == '3'
            # We'll use handler03 - I believe they're all compatible
            Handler03.new(connection, request, debug)
          else
            # According to spec should abort the connection
            raise WebSocketError, "Unknown draft version: #{version}"
          end
        elsif request['Sec-WebSocket-Key1']
          Handler76.new(connection, request, debug)
        else
          Handler75.new(connection, request, debug)
        end
      end
    end
  end
end
