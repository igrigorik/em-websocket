module EventMachine
  module WebSocket
    class HandlerFactory
      PATH   = /^(\w+) (\/[^\s]*) HTTP\/1\.1$/
      HEADER = /^([^:]+):\s*(.+)$/

      def self.build(data, secure = false, debug = false)
        request = {}
        response = nil

        lines = data.split("\r\n")

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
        request['Third-Key'] = lines.last

        unless request['Connection'] == 'Upgrade' and request['Upgrade'] == 'WebSocket'
          raise HandshakeError, "Connection and Upgrade headers required"
        end

        # transform headers
        protocol = (secure ? "wss" : "ws")
        request['Host'] = Addressable::URI.parse("#{protocol}://"+request['Host'])

        version = request['Sec-WebSocket-Key1'] ? 76 : 75

        case version
        when 75
          Handler75.new(request, response, debug)
        when 76
          Handler76.new(request, response, debug)
        else
          raise WebSocketError, "Must not happen"
        end
      end
    end
  end
end
