module EventMachine
  module WebSocket
    module Close10
      def close_websocket(code, body)
        send_close(code, body)
        @state = :closing
      end
    end
  end
end
