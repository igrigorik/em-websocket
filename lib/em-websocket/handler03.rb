module EventMachine
  module WebSocket
    class Handler03 < Handler
      include Handshake76
      include Framing03
    end
  end
end
