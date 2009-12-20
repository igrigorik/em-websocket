require 'spec/helper'

describe EventMachine::WebSocket do

  def failed
    EventMachine.stop
    fail
  end

  it "should automatically complete WebSocket handshake" do
    EM.run do
      EventMachine.add_timer(2) do
        http = EventMachine::HttpRequest.new('ws://127.0.0.1:8080/').get :timeout => 0
        http.errback { failed }
        http.callback {
          http.response_header.code.should == 101
          EventMachine.stop
        }
      end

      EventMachine::WebSocket.start(:host => "0.0.0.0", :port => 8080) do |ws|
        ws.on_open {
          puts "Connection open"
          puts ws.inspect
        }
      end
    end
  end

  it "should fail on non WebSocket requests" do
    EM.run do
      EventMachine.add_timer(2) do
        http = EventMachine::HttpRequest.new('http://127.0.0.1:8080/').get :timeout => 0
        http.errback { failed }
        http.callback {
          http.response_header.code.should == 400
          EventMachine.stop
        }
      end

      EventMachine::WebSocket.start(:host => "0.0.0.0", :port => 8080) do |ws|
        ws.on_open {
          puts "Connection open"
          puts ws.inspect
        }
      end
    end
  end

end