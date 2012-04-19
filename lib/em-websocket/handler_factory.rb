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

        raise HandshakeError, "Empty HTTP header" unless lines.size > 0

        # extract request path
        first_line = lines.shift.match(PATH)
        raise HandshakeError, "Invalid HTTP header" unless first_line
        request['method'] = first_line[1].strip
        request['path'] = first_line[2].strip

        unless request["method"] == "GET"
          raise HandshakeError, "Must be GET request"
        end

        # extract query string values
        request['query'] = Addressable::URI.parse(request['path']).query_values ||= {}
        # extract remaining headers
        lines.each do |line|
          h = HEADER.match(line)
          request[h[1].strip.downcase] = h[2].strip if h
        end

        build_with_request(connection, request, remains, secure, debug)
      end

      def self.build_with_request(connection, request, remains, secure = false, debug = false)
        # Determine version heuristically
        version = if request['sec-websocket-version']
          # Used from drafts 04 onwards
          request['sec-websocket-version'].to_i
        elsif request['sec-websocket-draft']
          # Used in drafts 01 - 03
          request['sec-websocket-draft'].to_i
        elsif request['sec-websocket-key1']
          76
        else
          75
        end

        # Additional handling of bytes after the header if required
        case version
        when 75
          if !remains.empty?
            raise HandshakeError, "Extra bytes after header"
          end
        when 76, 1..3
          if remains.length < 8
            # The whole third-key has not been received yet.
            return nil
          elsif remains.length > 8
            raise HandshakeError, "Extra bytes after third key"
          end
          request['third-key'] = remains
        end

        # Validate that Connection and Upgrade headers
        unless request['connection'] && request['connection'] =~ /Upgrade/ && request['upgrade'] && request['upgrade'].downcase == 'websocket'
          raise HandshakeError, "Connection and Upgrade headers required"
        end

        # transform headers
        protocol = (secure ? "wss" : "ws")
        request['host'] = Addressable::URI.parse("#{protocol}://"+request['host'])

        case version
        when 75
          Handler75.new(connection, request, debug)
        when 76
          Handler76.new(connection, request, debug)
        when 1..3
          # We'll use handler03 - I believe they're all compatible
          Handler03.new(connection, request, debug)
        when 5
          Handler05.new(connection, request, debug)
        when 6
          Handler06.new(connection, request, debug)
        when 7
          Handler07.new(connection, request, debug)
        when 8
          # drafts 9, 10, 11 and 12 should never change the version
          # number as they are all the same as version 08.
          Handler08.new(connection, request, debug)
        when 13
          # drafts 13 to 17 all identify as version 13 as they are
          # only minor changes or text changes.
          Handler13.new(connection, request, debug)
        else
          # According to spec should abort the connection
          raise HandshakeError, "Protocol version #{version} not supported"
        end
      end
    end
  end
end
