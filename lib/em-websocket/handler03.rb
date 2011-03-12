module EventMachine
  module WebSocket
    class Handler03 < Handler
      include Handshake76
      include Framing03
      include MessageProcessor03

      def close_websocket(code, body)
        # TODO: Ideally send body data and check that it matches in ack
        send_frame(:close, '')
        @state = :closing
      end
    end
  end
end
