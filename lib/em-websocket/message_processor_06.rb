module EventMachine
  module WebSocket
    module MessageProcessor06
      def message(message_type, extension_data, application_data)
        debug [:message_received, message_type, application_data]
        
        case message_type
        when :close
          status_code = case application_data.length
          when 0
            # close messages MAY contain a body
            nil
          when 1
            # Illegal close frame
            raise DataError, "Close frames with a body must contain a 2 byte status code"
          else
            application_data.slice!(0, 2).unpack('n').first
          end
          
          debug [:close_frame_received, status_code, application_data]
          
          if @state == :closing
            # We can close connection immediately since there is no more data
            # is allowed to be sent or received on this connection
            @connection.close_connection
            @state = :closed
          else
            # Acknowlege close
            # The connection is considered closed
            send_frame(:close, '')
            @state = :closed
            @connection.close_connection_after_writing
            # TODO: Send close status code and body to app code
          end
        when :ping
          # Pong back the same data
          send_frame(:pong, application_data)
        when :pong
          # TODO: Do something. Complete a deferrable established by a ping?
        when :text, :binary
          @connection.trigger_on_message(application_data)
        end
      end
    end
  end
end
