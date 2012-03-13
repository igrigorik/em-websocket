module EventMachine
  module WebSocket
    class Handler
      include Debugger

      attr_reader :request, :state

      def initialize(connection, debug = false)
        @connection = connection
        @debug = debug
        @state = :connected
        initialize_framing
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
