module EventMachine
  module WebSocket
    module Close06
      def close_websocket(code, body)
        if code
          close_data = [code].pack('n')
          close_data << body if body
          send_frame(:close, close_data)
        else
          send_frame(:close, '')
        end
        @state = :closing
      end
    end
  end
end
