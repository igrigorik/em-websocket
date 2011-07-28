module EventMachine
  module WebSocket
    class Handler08 < Handler
      include Handshake04
      include Framing08
      include MessageProcessor06
      include Close06
    end
  end
end
