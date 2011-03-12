module EventMachine
  module WebSocket
    class Handler05 < Handler
      include Handshake04
      include Framing05
      include MessageProcessor03
    end
  end
end
