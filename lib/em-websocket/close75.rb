module EventMachine
  module WebSocket
    module Close75
      def close_websocket(code, body)
        @state = :closed
        @connection.close_connection_after_writing
      end
    end
  end
end
