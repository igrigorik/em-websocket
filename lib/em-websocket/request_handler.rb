require 'digest/md5'

module EventMachine
  module WebSocket
    
    class RequestHandler
      PATH   = /^GET (\/[^\s]*) HTTP\/1\.1$/
      HEADER = /^([^:]+):\s*([^$]+)/
  
      attr_reader :request, :response, :version
  
      def initialize(debug = false)
        @debug = debug
        @request = {}
        @response = nil
        @version = nil
      end
    
      def parse(lines)
        # extract request path

        @request['Path'] = lines.shift.match(PATH)[1].strip
        # @request['Path'] = "/"
    
        # extract query string values
        @request['Query'] = Addressable::URI.parse(@request['Path']).query_values ||= {}
        # extract remaining headers
        lines.each do |line|
          h = HEADER.match(line)
          @request[h[1].strip] = h[2].strip if h
        end

        # This is only used for draft 76
        @request['Third-Key'] = lines.last

        # transform headers
        @request['Host'] = Addressable::URI.parse("ws://"+@request['Host'])
        
        @version = get_version(@request)
        raise unless @request['Connection'] == 'Upgrade' and @request['Upgrade'] == 'WebSocket'
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
        upgrade << "Sec-WebSocket-Protocol: #{@request['Sec-WebSocket-Protocol']}\r\n"  if @request['Sec-WebSocket-Protocol']
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