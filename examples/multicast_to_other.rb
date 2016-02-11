require 'em-websocket'
# requires the twitter-stream gem
require 'twitter/json_stream'
require 'json'

#
# broadcast all ruby related tweets to all connected users!
#

## custom handler must be EventMachine::WebSocket::Connection subclass
class Connection < EventMachine::WebSocket::Connection
  attr_accessor :cid # save my channel id
end

username = ARGV.shift
password = ARGV.shift
raise "need username and password" if !username or !password

EventMachine.run {
  @channel = EM::Channel.new

  @twitter = Twitter::JSONStream.connect(
    :path => '/1/statuses/filter.json?track=ruby',
    :auth => "#{username}:#{password}",
    :ssl => true
  )

  @twitter.each_item do |status|
    status = JSON.parse(status)
    @channel.push "#{status['user']['screen_name']}: #{status['text']}"
  end


  EventMachine::WebSocket.start(:host => "0.0.0.0", :port => 8080, :handler => Connection, :debug => true) do |ws|

    ws.onopen {
      ws.sid = @channel.subscribe { |pair| 
        sid, msg = pair
        ws.send msg if sid != ws.sid # send to others
      }

      @channel.push "#{sid} connected!"
    }

    ws.onmessage { |msg|
      @channel.push [ws.sid, msg]
    }

    ws.onclose {
      @channel.unsubscribe(sid)
    }

  end

  puts "Server started"
}
