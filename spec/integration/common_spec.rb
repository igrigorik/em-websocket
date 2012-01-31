require 'helper'

# These tests are not specific to any particular draft of the specification
# 
describe "WebSocket server" do
  include EM::SpecHelper
  default_timeout 1

  it "should fail on non WebSocket requests" do
    em {
      EventMachine.add_timer(0.1) do
        http = EventMachine::HttpRequest.new('http://127.0.0.1:12345/').get :timeout => 0
        http.errback { done }
        http.callback { fail }
      end

      EventMachine::WebSocket.start(:host => "0.0.0.0", :port => 12345) {}
    }
  end
  
  it "should populate ws.request with appropriate headers" do
    em {
      EventMachine.add_timer(0.1) do
        http = EventMachine::HttpRequest.new('ws://127.0.0.1:12345/').get :timeout => 0
        http.errback { fail }
        http.callback {
          http.response_header.status.should == 101
          http.close_connection
        }
        http.stream { |msg| }
      end

      EventMachine::WebSocket.start(:host => "0.0.0.0", :port => 12345) do |ws|
        ws.onopen {
          ws.request["user-agent"].should == "EventMachine HttpClient"
          ws.request["connection"].should == "Upgrade"
          ws.request["upgrade"].should == "WebSocket"
          ws.request["path"].should == "/"
          ws.request["origin"].should == "127.0.0.1"
          ws.request["host"].to_s.should == "ws://127.0.0.1:12345"
        }
        ws.onclose {
          ws.state.should == :closed
          EventMachine.stop
        }
      end
    }
  end
  
  it "should allow sending and retrieving query string args passed in on the connection request." do
    em {
      EventMachine.add_timer(0.1) do
        http = EventMachine::HttpRequest.new('ws://127.0.0.1:12345/').get(:query => {'foo' => 'bar', 'baz' => 'qux'}, :timeout => 0)
        http.errback { fail }
        http.callback {
          http.response_header.status.should == 101
          http.close_connection
        }
        http.stream { |msg| }
      end

      EventMachine::WebSocket.start(:host => "0.0.0.0", :port => 12345) do |ws|
        ws.onopen {
          path, query = ws.request["path"].split('?')
          path.should == '/'
          Hash[*query.split(/&|=/)].should == {"foo"=>"bar", "baz"=>"qux"}
          ws.request["query"]["foo"].should == "bar"
          ws.request["query"]["baz"].should == "qux"
        }
        ws.onclose {
          ws.state.should == :closed
          EventMachine.stop
        }
      end
    }
  end
  
  it "should ws.response['Query'] to empty hash when no query string params passed in connection URI" do
    em {
      EventMachine.add_timer(0.1) do
        http = EventMachine::HttpRequest.new('ws://127.0.0.1:12345/').get(:timeout => 0)
        http.errback { fail }
        http.callback {
          http.response_header.status.should == 101
          http.close_connection
        }
        http.stream { |msg| }
      end

      EventMachine::WebSocket.start(:host => "0.0.0.0", :port => 12345) do |ws|
        ws.onopen {
          ws.request["path"].should == "/"
          ws.request["query"].should == {}
        }
        ws.onclose {
          ws.state.should == :closed
          EventMachine.stop
        }
      end
    }
  end
  
  it "should raise an exception if frame sent before handshake complete" do
    em {
      EventMachine::WebSocket.start(:host => "0.0.0.0", :port => 12345) { |c|
        # We're not using a real client so the handshake will not be sent
        EM.add_timer(0.1) {
          lambda {
            c.send('early message')
          }.should raise_error('Cannot send data before onopen callback')
          done
        }
      }

      client = EM.connect('0.0.0.0', 12345, EM::Connection)
    }
  end
end
