module EventMachine
  module WebSocket
    class Handler10 < Handler
      include Handshake10
      include Framing10
      include Close10
    end
  end
end
