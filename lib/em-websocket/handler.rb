module EventMachine
  module WebSocket
    class Handler
      include Debugger

      attr_reader :request

      def initialize(request, response, debug = false)
        @request = request
        @response = response
        @debug = debug
      end

      def handshake
        # Implemented in subclass
      end
    end
  end
end
