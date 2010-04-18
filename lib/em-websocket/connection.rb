require 'addressable/uri'

module EventMachine
  module WebSocket
    class Connection < EventMachine::Connection

      PATH   = /^GET (\/[^\s]*) HTTP\/1\.1$/
      HEADER = /^([^:]+):\s*([^$]+)/

      attr_reader :state, :request

      # define WebSocket callbacks
      def onopen(&blk);     @onopen = blk;    end
      def onclose(&blk);    @onclose = blk;   end
      def onmessage(&blk);  @onmessage = blk; end

      def initialize(options)
        @options = options
        @debug = options[:debug] || false
        @state = :handshake
        @request = {}
        @data = ''
        @skip_onclose = false

        debug [:initialize]
      end

      def receive_data(data)
        debug [:receive_data, data]

        @data << data
        dispatch
      end

      def unbind
        debug [:unbind, :connection]

        @state = :closed
        @onclose.call if @onclose
      end

      def dispatch
        while case @state
          when :handshake
            new_request
          when :upgrade
            send_upgrade
          when :connected
            process_message
          else raise RuntimeError, "invalid state: #{@state}"
          end
        end
      end

      def new_request
        if @data.match(/\r\n\r\n$/)
          debug [:inbound_headers, @data]
          lines = @data.split("\r\n")

          begin
            # extract request path
            @request['Path'] = lines.shift.match(PATH)[1].strip

            # extract query string values
            @request['Query'] = Addressable::URI.parse(@request['Path']).query_values ||= {}

            # extract remaining headers
            lines.each do |line|
              h = HEADER.match(line)
              @request[h[1].strip] = h[2].strip
            end

            # transform headers
            @request['Host'] = Addressable::URI.parse("ws://"+@request['Host'])

            if not websocket_connection?
              process_bad_request
              return false
            else
              @data = ''
              @state = :upgrade
              return true
            end
          rescue => e
            debug [:error, e]
            process_bad_request
            return false
          end
        elsif @data.match(/<policy-file-request\s*\/>/)
          send_flash_cross_domain_file
          return false
        end

        false
      end

      def process_bad_request
        send_data "HTTP/1.1 400 Bad request\r\n\r\n"
        close_connection_after_writing
      end

      def websocket_connection?
        @request['Connection'] == 'Upgrade' and @request['Upgrade'] == 'WebSocket'
      end

      def send_upgrade
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
        send_data upgrade

        @state = :connected
        @onopen.call if @onopen

        # stop dispatch, wait for messages
        false
      end

      def send_flash_cross_domain_file
        file =  '<?xml version="1.0"?><cross-domain-policy><allow-access-from domain="*" to-ports="*"/></cross-domain-policy>'
        debug [:cross_domain, file]
        send_data file

        # handle the cross-domain request transparently
        # no need to notif the user about this connection
        @onclose = nil
        close_connection_after_writing
      end

      def process_message
        return if not @onmessage
        debug [:message, @data]

        # slice the message out of the buffer and pass in
        # for processing, and buffer data otherwise
        while msg = @data.slice!(/\000([^\377]*)\377/)
          msg.gsub!(/^\x00|\xff$/, '')
          @onmessage.call(msg)
        end

        false
      end

      # should only be invoked after handshake, otherwise it
      # will inject data into the header exchange
      #
      # frames need to start with 0x00-0x7f byte and end with
      # an 0xFF byte. Per spec, we can also set the first
      # byte to a value betweent 0x80 and 0xFF, followed by
      # a leading length indicator
      def send(data)
        debug [:send, data]
        send_data("\x00#{data}\xff")
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
