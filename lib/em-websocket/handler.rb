module EventMachine
  module WebSocket
    class Handler
      def self.klass_factory(version)
        case version
        when 75
          Handler75
        when 76
          Handler76
        when 1..3
          # We'll use handler03 - I believe they're all compatible
          Handler03
        when 5
          Handler05
        when 6
          Handler06
        when 7
          Handler07
        when 8
          # drafts 9, 10, 11 and 12 should never change the version
          # number as they are all the same as version 08.
          Handler08
        when 13
          # drafts 13 to 17 all identify as version 13 as they are
          # only minor changes or text changes.
          Handler13
        else
          # According to spec should abort the connection
          raise HandshakeError, "Protocol version #{version} not supported"
        end
      end

      include Debugger

      attr_reader :request, :state

      def initialize(connection, debug = false)
        @connection = connection
        @debug = debug
        @state = :connected
        initialize_framing
      end

      def receive_data(data)
        @data << data
        process_data(data)
      end

      def close_websocket(code, body)
        # Implemented in subclass
      end

      def unbind
        @state = :closed

        @close_info = defined?(@close_info) ? @close_info : {
          :code => 1006,
          :was_clean => false,
        }

        @connection.trigger_on_close(@close_info )
      end

      def ping
        # Overridden in subclass
        false
      end

      def pingable?
        # Also Overridden
        false
      end
    end
  end
end
