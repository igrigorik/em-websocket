module EventMachine
  module WebSocket
    class Handler06 < Handler
      include Handshake04
      include Framing05
      include MessageProcessor06
      
      def close_websocket(code, body)
        if code
          unless (4000..4999).include?(code)
            raise "Application code may only use codes in the range 4000-4999"
          end
          close_data = [code].pack('n')
          close_data << body
          send_frame(:close, close_data)
        else
          send_frame(:close, '')
        end
        @state = :closing
      end
    end
  end
end
