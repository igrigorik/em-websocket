require 'rubygems'
require 'em-websocket'

#this example must be used with the web_socket_command.js file.

EventMachine.run {
  @channel = EM::Channel.new

  EventMachine::WebSocket.start(:host => "0.0.0.0", :port => 8080, :debug => true) do |ws|

    ws.onopen {
      sid = @channel.subscribe { |msg| ws.send msg }
      @channel.push "#{sid} connected!"

      ws.onmessage { |msg|
        
        @channel.push ws.js_command('alert', 'test')
        #calls alert('test');
        
        @channel.push ws.js_command('prompt', 'prompt test', 9)
        #calls prompt('prompt test', 9);
        
        #javascript is a special command where the rest of the arguments are just evaluated.
        @channel.push ws.js_command('javascript', "alert('javascript alert')", "testval = 9+1", "alert(testval)")
        #runs the script below on the browser
        #     alert('javascript alert');
        #     testval = 9+1;
        #     alert(testval);
      }

      ws.onclose {
        @channel.unsubscribe(sid)
      }

    }
  end

  puts "Server started"
}
