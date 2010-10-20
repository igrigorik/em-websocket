require 'spec/helper'

describe EventMachine::WebSocket do

  it "should automatically complete WebSocket handshake" do
    EM.run do
      MSG = "Hello World!"
      EventMachine.add_timer(0.1) do
        http = EventMachine::HttpRequest.new('ws://127.0.0.1:12345/').get :timeout => 0
        http.errback { failed }
        http.callback { http.response_header.status.should == 101 }

        http.stream { |msg|
          msg.should == MSG
          EventMachine.stop
        }
      end

      EventMachine::WebSocket.start(:host => "0.0.0.0", :port => 12345) do |ws|
        ws.onopen {
          ws.send MSG
        }
      end
    end
  end

  it "should fail on non WebSocket requests" do
    EM.run do
      EventMachine.add_timer(0.1) do
        http = EventMachine::HttpRequest.new('http://127.0.0.1:12345/').get :timeout => 0
        http.errback { failed }
        http.callback {
          http.response_header.status.should == 400
          EventMachine.stop
        }
      end

      EventMachine::WebSocket.start(:host => "0.0.0.0", :port => 12345) {}
    end
  end

  it "should split multiple messages into separate callbacks" do
    EM.run do
      messages = %w[1 2]
      received = []

      EventMachine.add_timer(0.1) do
        http = EventMachine::HttpRequest.new('ws://127.0.0.1:12345/').get :timeout => 0
        http.errback { failed }
        http.stream {|msg|}
        http.callback {
          http.response_header.status.should == 101
          http.send messages[0]
          http.send messages[1]
        }
      end

      EventMachine::WebSocket.start(:host => "0.0.0.0", :port => 12345) do |ws|
        ws.onopen {}
        ws.onclose {}
        ws.onmessage {|msg|
          msg.should == messages[received.size]
          received.push msg

          EventMachine.stop if received.size == messages.size
        }
      end
    end
  end

  it "should call onclose callback when client closes connection" do
    EM.run do
      EventMachine.add_timer(0.1) do
        http = EventMachine::HttpRequest.new('ws://127.0.0.1:12345/').get :timeout => 0
        http.errback { failed }
        http.callback {
          http.response_header.status.should == 101
          http.close_connection
        }
        http.stream{|msg|}
      end

      EventMachine::WebSocket.start(:host => "0.0.0.0", :port => 12345) do |ws|
        ws.onopen {}
        ws.onclose {
          ws.state.should == :closed
          EventMachine.stop
        }
      end
    end
  end

  it "should call onerror callback with raised exception and close connection on bad handshake" do
    EM.run do
      EventMachine.add_timer(0.1) do
        http = EventMachine::HttpRequest.new('http://127.0.0.1:12345/').get :timeout => 0
        http.errback { http.response_header.status.should == 0 }
        http.callback { failed }
      end

      EventMachine::WebSocket.start(:host => "0.0.0.0", :port => 12345) do |ws|
        ws.onopen { failed }
        ws.onclose { EventMachine.stop }
        ws.onerror {|e|
          e.should be_an_instance_of EventMachine::WebSocket::HandshakeError
          e.message.should match('Connection and Upgrade headers required')
          EventMachine.stop
        }
      end
    end
  end

  it "should populate ws.request with appropriate headers" do
    EM.run do
      EventMachine.add_timer(0.1) do
        http = EventMachine::HttpRequest.new('ws://127.0.0.1:12345/').get :timeout => 0
        http.errback { failed }
        http.callback {
          http.response_header.status.should == 101
          http.close_connection
        }
        http.stream { |msg| }
      end

      EventMachine::WebSocket.start(:host => "0.0.0.0", :port => 12345) do |ws|
        ws.onopen {
          ws.request["User-Agent"].should == "EventMachine HttpClient"
          ws.request["Connection"].should == "Upgrade"
          ws.request["Upgrade"].should == "WebSocket"
          ws.request["Path"].should == "/"
          ws.request["Origin"].should == "127.0.0.1"
          ws.request["Host"].to_s.should == "ws://127.0.0.1:12345"
        }
        ws.onclose {
          ws.state.should == :closed
          EventMachine.stop
        }
      end
    end
  end

  it "should allow sending and retrieving query string args passed in on the connection request." do
    EM.run do
      EventMachine.add_timer(0.1) do
        http = EventMachine::HttpRequest.new('ws://127.0.0.1:12345/').get(:query => {'foo' => 'bar', 'baz' => 'qux'}, :timeout => 0)
        http.errback { failed }
        http.callback {
          http.response_header.status.should == 101
          http.close_connection
        }
        http.stream { |msg| }
      end

      EventMachine::WebSocket.start(:host => "0.0.0.0", :port => 12345) do |ws|
        ws.onopen {
          ws.request["Path"].should == "/?baz=qux&foo=bar"
          ws.request["Query"]["foo"].should == "bar"
          ws.request["Query"]["baz"].should == "qux"
        }
        ws.onclose {
          ws.state.should == :closed
          EventMachine.stop
        }
      end
    end
  end

  it "should ws.response['Query'] to empty hash when no query string params passed in connection URI" do
    EM.run do
      EventMachine.add_timer(0.1) do
        http = EventMachine::HttpRequest.new('ws://127.0.0.1:12345/').get(:timeout => 0)
        http.errback { failed }
        http.callback {
          http.response_header.status.should == 101
          http.close_connection
        }
        http.stream { |msg| }
      end

      EventMachine::WebSocket.start(:host => "0.0.0.0", :port => 12345) do |ws|
        ws.onopen {
          ws.request["Path"].should == "/"
          ws.request["Query"].should == {}
        }
        ws.onclose {
          ws.state.should == :closed
          EventMachine.stop
        }
      end
    end
  end

  it "should raise an exception if frame sent before handshake complete" do
    EM.run {
      EventMachine::WebSocket.start(:host => "0.0.0.0", :port => 12345) { |c|
        # We're not using a real client so the handshake will not be sent
        EM.add_timer(0.1) {
          lambda {
            c.send('early message')
          }.should raise_error('Cannot send data before onopen callback')
          EM.stop
        }
      }

      client = EM.connect('0.0.0.0', 12345, EM::Connection)
    }
  end
end
