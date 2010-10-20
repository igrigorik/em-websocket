module EventMachine
  module WebSocket
    class Handler
      include Debugger

      # Set the max frame lenth to very high value (10MB) until there is a
      # limit specified in the spec to protect against malicious attacks
      MAXIMUM_FRAME_LENGTH = 10 * 1024 * 1024

      attr_reader :request, :state

      def initialize(connection, request, debug = false)
        @connection, @request = connection, request
        @debug = debug
        @data = ''
        @state = :handshake
      end

      def run
        @connection.send_data handshake
        @state = :connected
        @connection.trigger_on_open
      end

      # Handshake response
      def handshake
        # Implemented in subclass
      end

      def receive_data(data)
        @data << data
        process_message
      end

      def unbind
        @state = :closed
        @connection.trigger_on_close
      end

      def process_message
        debug [:message, @data]

        # This algorithm comes straight from the spec
        # http://tools.ietf.org/html/draft-hixie-thewebsocketprotocol-76#section-4.2

        error = false

        while !error
          pointer = 0
          frame_type = @data[pointer].to_i
          pointer += 1

          if (frame_type & 0x80) == 0x80
            # If the high-order bit of the /frame type/ byte is set
            length = 0

            loop do
              b = @data[pointer].to_i
              return false unless b
              pointer += 1
              b_v = b & 0x7F
              length = length * 128 + b_v
              break unless (b & 0x80) == 0x80
            end

            # Addition to the spec to protect against malicious requests
            if length > MAXIMUM_FRAME_LENGTH
              @connection.close_with_error(DataError.new("Frame length too long (#{length} bytes)"))
              return false
            end

            if @data[pointer+length-1] == nil
              debug [:buffer_incomplete, @data.inspect]
              # Incomplete data - leave @data to accumulate
              error = true
            else
              # Straight from spec - I'm sure this isn't crazy...
              # 6. Read /length/ bytes.
              # 7. Discard the read bytes.
              @data = @data[(pointer+length)..-1]

              # If the /frame type/ is 0xFF and the /length/ was 0, then close
              if length == 0
                @connection.send_data("\xff\x00")
                @state = :closing
                @connection.close_connection_after_writing
              else
                error = true
              end
            end
          else
            # If the high-order bit of the /frame type/ byte is _not_ set
            msg = @data.slice!(/^\x00([^\xff]*)\xff/)
            if msg
              msg.gsub!(/\A\x00|\xff\z/, '')
              if @state == :closing
                debug [:ignored_message, msg]
              else
                msg.force_encoding('UTF-8') if msg.respond_to?(:force_encoding)
                @connection.trigger_on_message(msg)
              end
            else
              error = true
            end
          end
        end

        false
      end

      # frames need to start with 0x00-0x7f byte and end with
      # an 0xFF byte. Per spec, we can also set the first
      # byte to a value betweent 0x80 and 0xFF, followed by
      # a leading length indicator
      def send_frame(data)
        ary = ["\x00", data, "\xff"]
        ary.collect{ |s| s.force_encoding('UTF-8') if s.respond_to?(:force_encoding) }
        @connection.send_data(ary.join)
      end
    end
  end
end
