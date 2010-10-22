module EventMachine
  module WebSocket
    class Handler03 < Handler
      include Handshake76
      include Framing03

      def close_websocket
        # TODO: Should we send data and check the response matches?
        send_frame(:close, '')
        @state = :closing
      end
    end
  end
end
