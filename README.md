# EM-WebSocket

EventMachine based, async, Ruby WebSocket server. Take a look at examples directory, or check out the blog post below:

* [Ruby & Websockets: TCP for the Web](http://www.igvita.com/2009/12/22/ruby-websockets-tcp-for-the-browser/)

## Simple server example

```ruby
require 'em-websocket'

EM.run {
  EM::WebSocket.run(:host => "0.0.0.0", :port => 8080) do |ws|
    ws.onopen { |handshake|
      puts "WebSocket connection open"

      # Access properties on the EM::WebSocket::Handshake object, e.g.
      # path, query_string, origin, headers

      # Publish message to the client
      ws.send "Hello Client, you connected to #{handshake.path}"
    }

    ws.onclose { puts "Connection closed" }

    ws.onmessage { |msg|
      puts "Recieved message: #{msg}"
      ws.send "Pong: #{msg}"
    }
  end
}
```

## Secure server

It is possible to accept secure `wss://` connections by passing `:secure => true` when opening the connection. Pass a `:tls_options` hash containing keys as described in http://eventmachine.rubyforge.org/EventMachine/Connection.html#start_tls-instance_method

**Warning**: Safari 5 does not currently support prompting on untrusted SSL certificates therefore using a self signed certificate may leave you scratching your head.

```ruby
EM::WebSocket.start({
  :host => "0.0.0.0",
  :port => 443,
  :secure => true,
  :tls_options => {
    :private_key_file => "/private/key",
    :cert_chain_file => "/ssl/certificate"
  }
}) do |ws|
  # ...
end
```

## Running behind an SSL Proxy/Terminator, like Stunnel

The `:secure_proxy => true` option makes it possible to use em-websocket behind a secure SSL proxy/terminator like [Stunnel](http://www.stunnel.org/) which does the actual encryption & decryption.

Note that this option is only required to support drafts 75 & 76 correctly (e.g. Safari 5.1.x & earlier, and Safari on iOS 5.x & earlier).

```ruby
EM::WebSocket.start({
  :host => "0.0.0.0",
  :port => 8080,
  :secure_proxy => true
}) do |ws|
  # ...
end
```

## Handling errors

There are two kinds of errors that need to be handled -- WebSocket protocol errors and errors in application code.

WebSocket protocol errors (for example invalid data in the handshake or invalid message frames) raise errors which descend from `EM::WebSocket::WebSocketError`. Such errors are rescued internally and the WebSocket connection will be closed immediately or an error code sent to the browser in accordance to the WebSocket specification. It is possible to be notified in application code of such errors by including an `onerror` callback.

```ruby
ws.onerror { |error|
  if error.kind_of?(EM::WebSocket::WebSocketError)
    # ...
  end
}
```

Application errors are treated differently. If no `onerror` callback has been defined these errors will propagate to the EventMachine reactor, typically causing your program to terminate. If you wish to handle exceptions, simply supply an `onerror callback` and check for exceptions which are not descendant from `EM::WebSocket::WebSocketError`.

It is also possible to log all errors when developing by including the `:debug => true` option when initialising the WebSocket server.

## Emulating WebSockets in older browsers

It is possible to emulate WebSockets in older browsers using flash emulation. For example take a look at the [web-socket-js](https://github.com/gimite/web-socket-js) project.

Using flash emulation does require some minimal support from em-websocket which is enabled by default. If flash connects to the WebSocket port and requests a policy file (which it will do if it fails to receive a policy file on port 843 after a timeout), em-websocket will return one. Also see <https://github.com/igrigorik/em-websocket/issues/61> for an example policy file server which you can run on port 843.

## Examples & Projects using em-websocket

* [Pusher](http://pusher.com) - Realtime Messaging Service
* [Livereload](https://github.com/mockko/livereload) - LiveReload applies CSS/JS changes to Safari or Chrome w/o reloading
* [Twitter AMQP WebSocket Example](http://github.com/rubenfonseca/twitter-amqp-websocket-example)
* examples/multicast.rb - broadcast all ruby tweets to all subscribers
* examples/echo.rb - server <> client exchange via a websocket

# License

The MIT License - Copyright (c) 2009 Ilya Grigorik
