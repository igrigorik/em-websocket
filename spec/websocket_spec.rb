require 'spec/helper'

describe EventMachine::WebSocket do

  def failed
    EventMachine.stop
    fail
  end

  it "should automatically complete WebSocket handshake" do
    EM.run do
      MSG = "Hello World!"
      EventMachine.add_timer(0.1) do
        http = EventMachine::HttpRequest.new('ws://127.0.0.1:8080/').get :timeout => 0
        http.errback { failed }
        http.callback { http.response_header.status.should == 101 }

        http.stream { |msg|
          msg.should == MSG
          EventMachine.stop
        }
      end

      EventMachine::WebSocket.start(:host => "0.0.0.0", :port => 8080) do |ws|
        ws.onopen {
          puts "WebSocket connection open"
          ws.send MSG
        }

        # TODO: need .terminate method on EM-http to invoke & test .onclose callback
      end
    end
  end

  it "should fail on non WebSocket requests" do
    pending

    EM.run do
      EventMachine.add_timer(0.1) do
        http = EventMachine::HttpRequest.new('http://127.0.0.1:8080/').get :timeout => 0
        http.errback { failed }
        http.callback {
          http.response_header.status.should == 400
          EventMachine.stop
        }
      end

      EventMachine::WebSocket.start(:host => "0.0.0.0", :port => 8080, :debug => true) {}
    end
  end

end