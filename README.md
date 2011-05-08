# EM-WebSocket

EventMachine based, async, Ruby WebSocket server. Take a look at examples directory, or check out the blog post below:

* [Ruby & Websockets: TCP for the Web](http://www.igvita.com/2009/12/22/ruby-websockets-tcp-for-the-browser/)

## Simple server example

```ruby
EventMachine.run {

    EventMachine::WebSocket.start(:host => "0.0.0.0", :port => 8080) do |ws|
        ws.onopen {
          puts "WebSocket connection open"

          # publish message to the client
          ws.send "Hello Client"
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

It is possible to accept secure wss:// connections by passing :secure => true when opening the connection. Safari 5 does not currently support prompting on untrusted SSL certificates therefore using signed certificates is highly recommended. Pass a :tls_options hash containing keys as described in http://eventmachine.rubyforge.org/EventMachine/Connection.html#M000296

For example,

```ruby
EventMachine::WebSocket.start({
    :host => "0.0.0.0",
    :port => 443
    :secure => true,
    :tls_options => {
      :private_key_file => "/private/key",
      :cert_chain_file => "/ssl/certificate"
    }
}) do |ws|
...
end
```

## Handling errors

There are two kinds of errors that need to be handled - errors caused by incompatible WebSocket clients sending invalid data and errors in application code. They are handled as follows:

Errors caused by invalid WebSocket data (for example invalid errors in the WebSocket handshake or invalid message frames) raise errors which descend from `EventMachine::WebSocket::WebSocketError`. Such errors are rescued internally and the WebSocket connection will be closed immediately or an error code sent to the browser in accordance to the WebSocket specification. However it is possible to be notified in application code on such errors by including an `onerror` callback.

```ruby
ws.onerror { |error|
  if e.kind_of?(EM::WebSocket::WebSocketError)
    ...
  end
}
```

Application errors are treated differently. If no `onerror` callback has been defined these errors will propagate to the EventMachine reactor, typically causing your program to terminate. If you wish to handle exceptions, simply supply an `onerror callback` and check for exceptions which are not decendant from `EventMachine::WebSocket::WebSocketError`.

It is also possible to log all errors when developing by including the `:debug => true` option when initialising the WebSocket connection.

## Examples & Projects using em-websocket

* [Pusher](http://pusherapp.com) - Realtime client push
* [Livereload](https://github.com/mockko/livereload) - LiveReload applies CSS/JS changes to Safari or Chrome w/o reloading
* [Twitter AMQP WebSocket Example](http://github.com/rubenfonseca/twitter-amqp-websocket-example)
* examples/multicast.rb - broadcast all ruby tweets to all subscribers
* examples/echo.rb - server <> client exchange via a websocket

# License

The MIT License - Copyright (c) 2009 Ilya Grigorik