module EventMachine
  module WebSocket
    class Handler
      include Debugger

      attr_reader :request, :state

      def initialize(connection, request, debug = false)
        @connection, @request = connection, request
        @debug = debug
        @state = :handshake
        initialize_framing
      end

      def run
        @connection.send_data handshake
        @state = :connected
        @connection.trigger_on_open
      end

      # Handshake response
      def handshake
        # Implemented in subclass
      end

      def receive_data(data)
        @data << data
        process_data
      end

      def unbind
        @state = :closed
        @connection.trigger_on_close
      end

      # frames need to start with 0x00-0x7f byte and end with
      # an 0xFF byte. Per spec, we can also set the first
      # byte to a value betweent 0x80 and 0xFF, followed by
      # a leading length indicator
      def send_frame(data)
        ary = ["\x00", data, "\xff"]
        ary.collect{ |s| s.force_encoding('UTF-8') if s.respond_to?(:force_encoding) }
        @connection.send_data(ary.join)
      end
    end
  end
end
