module EventMachine
  module WebSocket
    # All errors raised by em-websocket should descend from this class
    #
    class WebSocketError < RuntimeError; end

    # Used for errors that occur during WebSocket handshake
    #
    class HandshakeError < WebSocketError; end

    # Used for errors which should cause the connection to close.
    # See RFC6455 §7.4.1 for a full description of meanings
    #
    class WSProtocolError < WebSocketError
      def code; 1002; end
    end

    # 1009: Message too big to process
    class WSMessageTooBigError < WSProtocolError
      def code; 1009; end
    end

    def self.start(options, &blk)
      EM.epoll
      EM.run do

        trap("TERM") { stop }
        trap("INT")  { stop }

        EventMachine::start_server(options[:host], options[:port],
          EventMachine::WebSocket::Connection, options) do |c|
          blk.call(c)
        end
      end
    end

    def self.stop
      puts "Terminating WebSocket Server"
      EventMachine.stop
    end

    class << self
      attr_accessor :max_frame_size
    end
    @max_frame_size = 10 * 1024 * 1024 # 10MB
  end
end
