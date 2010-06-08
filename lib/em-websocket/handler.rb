module EventMachine
  module WebSocket
    class HandshakeError < RuntimeError; end

    class Handler
      attr_reader :request

      def initialize(request, response, debug = false)
        @request = request
        @response = response
        @debug = debug
      end

      def handshake
        # Implemented in subclass
      end

      def should_close?(data)
        false
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
