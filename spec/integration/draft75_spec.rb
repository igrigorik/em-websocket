require 'helper'
require 'integration/shared_examples'

# These integration tests are older and use a different testing style to the 
# integration tests for newer drafts. They use EM::HttpRequest which happens 
# to currently estabish a websocket connection using the draft75 protocol.
# 
describe "WebSocket server draft75" do
  include EM::SpecHelper
  default_timeout 1

  def start_server
    EM::WebSocket.run(:host => "0.0.0.0", :port => 12345) { |ws|
      yield ws if block_given?
    }
  end

  def start_client
    client = Draft75WebSocketClient.new
    yield client if block_given?
    return client
  end

  it_behaves_like "a websocket server" do
    let(:version) { 75 }
  end

  it "should automatically complete WebSocket handshake" do
    em {
      MSG = "Hello World!"
      EventMachine.add_timer(0.1) do
        http = EventMachine::HttpRequest.new('ws://127.0.0.1:12345/').get :timeout => 0
        http.errback { fail }
        http.callback { http.response_header.status.should == 101 }

        http.stream { |msg|
          msg.should == MSG
          EventMachine.stop
        }
      end

      start_server { |ws|
        ws.onopen {
          ws.send MSG
        }
      }
    }
  end

  it "should split multiple messages into separate callbacks" do
    em {
      messages = %w[1 2]
      received = []

      EventMachine.add_timer(0.1) do
        http = EventMachine::HttpRequest.new('ws://127.0.0.1:12345/').get :timeout => 0
        http.errback { fail }
        http.stream {|msg|}
        http.callback {
          http.response_header.status.should == 101
          http.send messages[0]
          http.send messages[1]
        }
      end

      start_server { |ws|
        ws.onopen {}
        ws.onclose {}
        ws.onmessage {|msg|
          msg.should == messages[received.size]
          received.push msg

          EventMachine.stop if received.size == messages.size
        }
      }
    }
  end

  it "should call onclose callback when client closes connection" do
    em {
      EventMachine.add_timer(0.1) do
        http = EventMachine::HttpRequest.new('ws://127.0.0.1:12345/').get :timeout => 0
        http.errback { fail }
        http.callback {
          http.response_header.status.should == 101
          http.close_connection
        }
        http.stream{|msg|}
      end

      start_server { |ws|
        ws.onopen {}
        ws.onclose {
          ws.state.should == :closed
          EventMachine.stop
        }
      }
    }
  end

  it "should call onerror callback with raised exception and close connection on bad handshake" do
    em {
      EventMachine.add_timer(0.1) do
        http = EventMachine::HttpRequest.new('http://127.0.0.1:12345/').get :timeout => 0
        http.errback { http.response_header.status.should == 0 }
        http.callback { fail }
      end

      start_server { |ws|
        ws.onopen { fail }
        ws.onclose { EventMachine.stop }
        ws.onerror {|e|
          e.should be_an_instance_of EventMachine::WebSocket::HandshakeError
          e.message.should match('Not an upgrade request')
          EventMachine.stop
        }
      }
    }
  end

  it "should report that close codes are not supported" do
    em {
      start_server { |ws|
        ws.onopen {
          ws.supports_close_codes?.should == false
          done
        }
      }
      start_client
    }
  end
end
