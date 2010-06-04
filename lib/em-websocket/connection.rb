require 'addressable/uri'

module EventMachine
  module WebSocket
    class Connection < EventMachine::Connection
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
        
        if @handler && @handler.should_close?(data)
          send_data(data) 
          unbind
        else
          @data << data
          dispatch
        end
      end

      def unbind
        debug [:unbind, :connection]

        @state = :closed
        @onclose.call if @onclose
      end

      def dispatch
        case @state
          when :handshake
            handshake
          when :connected
            process_message
          else raise RuntimeError, "invalid state: #{@state}"
        end
      end

      def handshake
        if @data.match(/<policy-file-request\s*\/>/)
          send_flash_cross_domain_file
          return false
        else
          debug [:inbound_headers, @data]
          begin
            @handler = HandlerFactory.build(@data, @debug)
            send_data @handler.handshake

            @request = @handler.request
            @state = :connected
            @onopen.call if @onopen
            return true
          rescue => e
            debug [:error, e]
            process_bad_request
            return false
          end
        end
      end

      def process_bad_request
        send_data "HTTP/1.1 400 Bad request\r\n\r\n"
        close_connection_after_writing
      end

      def websocket_connection?
        @request['Connection'] == 'Upgrade' and @request['Upgrade'] == 'WebSocket'
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
