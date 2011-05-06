module EventMachine
  module WebSocket
    class Handler06 < Handler
      include Handshake04
      include Framing05
      include MessageProcessor06
      include Close06
    end
  end
end
