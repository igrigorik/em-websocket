module EventMachine
  module WebSocket
    module Framing03
      
      def initialize_framing
        @data = ''
        @application_data_buffer = '' # Used for MORE frames
      end
      
      def process_data
        error = false

        while !error && @data.size > 1
          pointer = 0

          more = (@data[pointer] & 0b10000000) == 0b10000000
          # Ignoring rsv1-3 for now
          opcode = @data[0] & 0b00001111
          pointer += 1

          # Ignoring rsv4
          length = @data[pointer] & 0b01111111
          pointer += 1

          payload_length = case length
          when 127 # Length defined by 8 bytes
            # Check buffer size
            if @data[pointer+8-1] == nil
              debug [:buffer_incomplete, @data.inspect]
              error = true
              next
            end
            
            # Only using the last 4 bytes for now, till I work out how to
            # unpack 8 bytes. I'm sure 4GB frames will do for now :)
            l = @data[(pointer+4)..(pointer+7)].unpack('N').first
            pointer += 8
            l
          when 126 # Length defined by 2 bytes
            # Check buffer size
            if @data[pointer+2-1] == nil
              debug [:buffer_incomplete, @data.inspect]
              error = true
              next
            end
            
            l = @data[pointer..(pointer+1)].unpack('n').first
            pointer += 2
            l
          else
            length
          end

          # Check buffer size
          if @data[pointer+payload_length-1] == nil
            debug [:buffer_incomplete, @data.inspect]
            error = true
            next
          end

          # Throw away data up to pointer
          @data.slice!(0...pointer)

          # Read application data
          application_data = @data.slice!(0...payload_length)

          frame_type = case opcode
          when 0
            raise('Continuation frame not expected') unless @frame_type
            :continuation
          when 1
            :close
          when 2
            :ping
          when 3
            :pong
          when 4
            :text
          when 5
            :binary
          else
            :reserved
          end

          if more
            debug [:moreframe, frame_type, application_data]
            @application_data_buffer << application_data
            @frame_type = frame_type
          else
            # Message is complete
            if frame_type == :continuation
              @application_data_buffer << application_data
              message(@frame_type, '', @application_data_buffer)
              @application_data_buffer = ''
              @frame_type = nil
            else
              message(frame_type, '', application_data)
            end
          end
        end # end while
      end
      
      def message(message_type, extension_data, application_data)
        # TODO
      end
    end
  end
end
