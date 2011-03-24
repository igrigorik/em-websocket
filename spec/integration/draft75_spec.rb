require 'helper'
require 'integration/shared_examples'

# These integration tests are older and use a different testing style to the 
# integration tests for newer drafts. They use EM::HttpRequest which happens 
# to currently estabish a websocket connection using the draft75 protocol.
# 
describe "WebSocket server draft75" do

  it_behaves_like "a websocket server" do
    def start_server
      EM::WebSocket.start(:host => "0.0.0.0", :port => 12345) { |ws|
        yield ws
      }
    end

    def start_client
      client = Draft75WebSocketClient.new
      yield client if block_given?
    end
  end

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
end
