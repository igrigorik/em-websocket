module EventMachine
  module WebSocket
    class Handler05 < Handler
      include Handshake04
      include Framing05
      include MessageProcessor03
      include Close05
    end
  end
end
