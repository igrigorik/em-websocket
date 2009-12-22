module EventMachine
  module WebSocket
    class Connection < EventMachine::Connection

      # define WebSocket callbacks
      def onopen(&blk);     @onopen = blk;    end
      def onclose(&blk);    @onclode = blk;   end
      def onmessage(&blk);  @onmessage = blk; end

      def initialize(options)
        @options = options
        @debug = options[:debug] || false
        @state = :handshake

        debug [:initialize]
      end

      def receive_data(data)
        debug [:receive_data, data]
       
        dispatch(data)
      end

      def unbind
        debug [:unbind, :connection]
        @onclose.call if @onclose
      end

      def dispatch(data = nil)
        while case @state
          when :handshake
            new_request(data)
          when :upgrade
            send_upgrade
          when :connected
            process_message(data)
          else raise RuntimeError, "invalid state: #{@state}"
          end
        end
      end

      def new_request(data)
        # TODO: verify WS headers
        @state = :upgrade
      end

      def send_upgrade
        upgrade = "HTTP/1.1 101 Web Socket Protocol Handshake\r\n"
        upgrade << "Upgrade: WebSocket\r\n"
        upgrade << "Connection: Upgrade\r\n"
        upgrade << "WebSocket-Origin: file://\r\n"
        upgrade << "WebSocket-Location: ws://localhost:8080/\r\n\r\n"

        # upgrade connection and notify client callback
        # about completed handshake
        send_data upgrade

        @state = :connected
        @onopen.call if @onopen

        # stop dispatch, wait for messages
        false
      end

      def process_message(data)
        debug [:message, data]
        @onmessage.call(data) if @onmessage

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
