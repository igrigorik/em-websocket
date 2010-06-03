module EventMachine
  module WebSocket
    class RequestHandler
      PATH   = /^GET (\/[^\s]*) HTTP\/1\.1$/
      HEADER = /^([^:]+):\s*([^$]+)/
  
      attr_reader :request, :response, :version
  
      def initialize
        @request = {}
        @response = nil
        @version = nil
      end
    
      def parse(lines)
        # extract request path
        # @request['Path'] = aa.match(PATH)[0].strip

        @request['Path'] = lines.shift.match(PATH)[1].strip
        # @request['Path'] = "/"
    
        p lines

        # extract query string values
        @request['Query'] = Addressable::URI.parse(@request['Path']).query_values ||= {}
    
        # extract remaining headers
    
        lines.each do |line|
          h = HEADER.match(line)
          @request[h[1].strip] = h[2].strip
        end
    
        # transform headers
        @request['Host'] = Addressable::URI.parse("ws://"+@request['Host'])

        raise unless @request['Connection'] == 'Upgrade' and @request['Upgrade'] == 'WebSocket'
        location  = "ws://#{@request['Host'].host}"
        location << ":#{@request['Host'].port}" if @request['Host'].port
        location << @request['Path']

        upgrade =  "HTTP/1.1 101 Web Socket Protocol Handshake\r\n"
        upgrade << "Upgrade: WebSocket\r\n"
        upgrade << "Connection: Upgrade\r\n"
        upgrade << "WebSocket-Origin: #{@request['Origin']}\r\n"
        upgrade << "WebSocket-Location: #{location}\r\n\r\n"

        # upgrade connection and notify client callback
        # about completed handshake
        debug [:upgrade_headers, upgrade]
        @response = upgrade
        return true
      end
    private
      def debug(*data)
        if @debug
          require 'pp'
          pp data
          puts
        end
      end
    end
  end
end