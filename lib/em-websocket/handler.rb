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
        process_data(data)
      end

      def close_websocket(code, body)
        # Implemented in subclass
      end

      def unbind
        @state = :closed
        @connection.trigger_on_close
      end

      def ping
        # Overridden in subclass
        false
      end

      def pingable?
        # Also Overridden
        false
      end
    end
  end
end
