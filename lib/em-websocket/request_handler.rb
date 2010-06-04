require 'digest/md5'

module EventMachine
  module WebSocket
    class HandshakeError < RuntimeError; end
    
    class RequestHandler
      PATH   = /^(\w+) (\/[^\s]*) HTTP\/1\.1$/
      HEADER = /^([^:]+):\s*([^$]+)/
  
      attr_reader :request, :response, :version
  
      def initialize(debug = false)
        @debug = debug
        @request = {}
        @response = nil
        @version = nil
      end
    
      def parse(data)
        lines = data.split("\r\n")

        # extract request path
        first_line = lines.shift.match(PATH)
        @request['Method'] = first_line[1].strip
        @request['Path'] = first_line[2].strip

        unless @request["Method"] == "GET"
          raise HandshakeError, "Must be GET request"
        end
    
        # extract query string values
        @request['Query'] = Addressable::URI.parse(@request['Path']).query_values ||= {}
        # extract remaining headers
        lines.each do |line|
          h = HEADER.match(line)
          @request[h[1].strip] = h[2].strip if h
        end

        unless @request['Connection'] == 'Upgrade' and @request['Upgrade'] == 'WebSocket'
          raise HandshakeError, "Connection and Upgrade headers required"
        end

        # This is only used for draft 76
        @request['Third-Key'] = lines.last

        # transform headers
        @request['Host'] = Addressable::URI.parse("ws://"+@request['Host'])
        
        @version = get_version(@request)

        @response = send("set_response_header_#{@version}")
        # upgrade connection and notify client callback
        # about completed handshake
        debug [:upgrade_headers, @response]
        return true
      end
      
      def set_response_header_76
        challenge_response = solve_challange(
          @request['Sec-WebSocket-Key1'], 
          @request['Sec-WebSocket-Key2'], 
          @request['Third-Key']
        )
        
        location  = "ws://#{@request['Host'].host}"
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
      end
      
      def set_response_header_75
        location  = "ws://#{@request['Host'].host}"
        location << ":#{@request['Host'].port}" if @request['Host'].port
        location << @request['Path']

        upgrade =  "HTTP/1.1 101 Web Socket Protocol Handshake\r\n"
        upgrade << "Upgrade: WebSocket\r\n"
        upgrade << "Connection: Upgrade\r\n"
        upgrade << "WebSocket-Origin: #{@request['Origin']}\r\n"
        upgrade << "WebSocket-Location: #{location}\r\n\r\n"
      end

    private

      def solve_challange(first, second, third)
        # Refer to 5.2 4-9 of the draft 76
        sum = (extract_nums(first) / count_spaces(first)).to_a.pack("N*") +
              (extract_nums(second) / count_spaces(second)).to_a.pack("N*") +
              third
        Digest::MD5.digest(sum)
      end
      
      def extract_nums(string)
        string.scan(/[0-9]/).join.to_i
      end
      
      def count_spaces(string)
        string.scan(/ /).size        
      end
    
      def get_version(request)
        request['Sec-WebSocket-Key1'] ? 76 : 75
      end

      def validate_protocol!(protocol)
        raise HandshakeError, "Invalid WebSocket-Protocol: empty" if protocol.empty?
        # TODO: Validate characters
      end
    
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
