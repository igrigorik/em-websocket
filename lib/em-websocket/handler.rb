module EventMachine
  module WebSocket
    class Handler
      include Debugger

      attr_reader :request

      def initialize(connection, request, debug = false)
        @connection, @request = connection, request
        @debug = debug
      end

      def handshake
        # Implemented in subclass
      end
    end
  end
end
