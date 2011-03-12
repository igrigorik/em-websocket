module EventMachine
  module WebSocket
    class Handler05 < Handler
      include Handshake04
      include Framing05
      include MessageProcessor03

      def close_websocket(code, body)
        # TODO: Ideally send body data and check that it matches in ack
        send_frame(:close, "\x53")
        @state = :closing
      end
    end
  end
end
