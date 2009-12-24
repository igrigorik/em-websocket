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
          ws.send MSG
        }
      end
    end
  end

  it "should fail on non WebSocket requests" do
    EM.run do
      EventMachine.add_timer(0.1) do
        http = EventMachine::HttpRequest.new('http://127.0.0.1:8080/').get :timeout => 0
        http.errback { failed }
        http.callback {
          http.response_header.status.should == 400
          EventMachine.stop
        }
      end

      EventMachine::WebSocket.start(:host => "0.0.0.0", :port => 8080) {}
    end
  end

  #  it "should split multiple messages into separate callbacks" do
  #    EM.run do
  #      messages = %w[1 2]
  #      recieved = []
  #
  #      EventMachine.add_timer(0.1) do
  #        http = EventMachine::HttpRequest.new('ws://127.0.0.1:8080/').get :timeout => 0
  #        http.errback { failed }
  #        http.callback { http.response_header.status.should == 101 }
  #        http.stream {|msg|
  #          p msg.inspect
  #
  #          msg.should == messages[recieved.size]
  #          recieved.push msg
  #
  #          EventMachine.stop if recieved.size == messages.size
  #        }
  #      end
  #
  #      EventMachine::WebSocket.start(:host => "0.0.0.0", :port => 8080, :debug => true) do |ws|
  #        ws.onopen {
  #          puts "WebSocket connection open"
  #          ws.send messages[0]
  #          ws.send messages[1]
  #        }
  #      end
  #    end
  #  end

  it "should split multiple messages into separate callbacks" do
    EM.run do
      messages = %w[1 2]
      recieved = []

      EventMachine.add_timer(0.1) do
        http = EventMachine::HttpRequest.new('ws://127.0.0.1:8080/').get :timeout => 0
        http.errback { failed }
        http.callback {
          http.response_header.status.should == 101
          http.send messages[0]
          http.send messages[1]
        }
      end

      EventMachine::WebSocket.start(:host => "0.0.0.0", :port => 8080) do |ws|
        ws.onopen {}
        ws.onmessage {|msg|
          msg.should == messages[recieved.size]
          recieved.push msg

          EventMachine.stop if recieved.size == messages.size
        }
      end
    end
  end

  #  it "should call onclose callback when client closes connection" do
  #    EM.run do
  #      EventMachine.add_timer(0.1) do
  #        http = EventMachine::HttpRequest.new('ws://127.0.0.1:8080/').get :timeout => 0
  #        http.errback { failed }
  #        http.callback {
  #          http.response_header.status.should == 101
  #          http.close_connection(true)
  #          p 'wtf'
  #        }
  #      end
  #
  #      EventMachine::WebSocket.start(:host => "0.0.0.0", :port => 8080) do |ws|
  #        ws.onopen {}
  #        ws.onclose {
  #          puts 'closing!'
  #          EventMachine.stop
  #        }
  #      end
  #    end
  #  end

end