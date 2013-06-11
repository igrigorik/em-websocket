require File.expand_path('../../lib/em-websocket', __FILE__)

EM.run do
  EventMachine::WebSocket.start(:host => "0.0.0.0", :port => 8282, :debug => true) do |ws|

    #
    #   Do authentication/authorization in onhandshake. We can return HTTP status codes
    #   to indicate failure
    #
    ws.onhandshake {|handshake|
      puts "handshake path: #{handshake.path}"
      
      # If the return code is true or 101 (web socket upgrade success),
      # continue with the websocket upgrade response to upgrade the HTTP
      # connection to a websocket (ws.onopen will then be invoked)
      ret = true  
      ret = 101

      # We can inspect the handshake .path, .query, or .headers to do our auth
      # For example, we may want to verify that the client passes some long,
      # predetermined session key, validate it in our persistent session store,
      # and deny access if it is invalid. This contrived example inspects the
      # path
      if handshake.path == '/forbidden'
        ret = 403
      end

      # raise HttpStatusForbidden (indicates HTTP 403) or another subclass of
      # HandshakeError to deny access. Returning a numeric status code is syntactic
      # sugar for calling:
      #
      #       raise HttpErrorStatus.new(http_error_code)
      #
      if handshake.query['authorized'] == 'false'
        raise EventMachine::WebSocket::HttpStatusForbidden
      end

      ret 
    }

    ws.onopen {|handshake|
      ws.send "Auth succeeded. You are connected to a websocket."
    }

    ws.onclose {
    }
    
  end
end

