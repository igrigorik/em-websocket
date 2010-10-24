module EventMachine
  module WebSocket
    class HandlerFactory
      PATH   = /^(\w+) (\/[^\s]*) HTTP\/1\.1$/
      HEADER = /^([^:]+):\s*(.+)$/

      def self.build(data, secure = false, debug = false)
        (header, remains) = data.split("\r\n\r\n", 2)
        unless remains
          # The whole header has not been received yet.
          return [nil, data]
        end

        request = {}
        response = nil

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
        if version == 76
          if remains.length < 8
            # The whole third-key has not been received yet.
            return [nil, data]
          end
          request['Third-Key'] = remains[0, 8]
          remains = remains[8..-1]
        end

        unless request['Connection'] == 'Upgrade' and request['Upgrade'] == 'WebSocket'
          raise HandshakeError, "Connection and Upgrade headers required"
        end

        # transform headers
        protocol = (secure ? "wss" : "ws")
        request['Host'] = Addressable::URI.parse("#{protocol}://"+request['Host'])

        case version
        when 75
          handler = Handler75.new(request, response, debug)
        when 76
          handler = Handler76.new(request, response, debug)
        else
          raise WebSocketError, "Must not happen"
        end
        return [handler, remains]
      end
    end
  end
end
