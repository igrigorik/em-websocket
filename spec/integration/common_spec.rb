require 'helper'

# These tests are not specific to any particular draft of the specification
#
describe "WebSocket server" do
  include EM::SpecHelper
  default_timeout 1

  it "should fail on non WebSocket requests" do
    em {
      EM.add_timer(0.1) do
        http = EM::HttpRequest.new('http://127.0.0.1:12345/').get :timeout => 0
        http.errback { done }
        http.callback { fail }
      end

      EM::WebSocket.start(:host => "0.0.0.0", :port => 12345) {}
    }
  end

  it "should expose the WebSocket request headers, path and query params" do
    em {
      EM.add_timer(0.1) do
        http = EM::HttpRequest.new('ws://127.0.0.1:12345/').get :timeout => 0
        http.errback { fail }
        http.callback {
          http.response_header.status.should == 101
          http.close_connection
        }
        http.stream { |msg| }
      end

      EM::WebSocket.start(:host => "0.0.0.0", :port => 12345) do |ws|
        ws.onopen { |handshake|
          headers = handshake.headers
          headers["User-Agent"].should == "EventMachine HttpClient"
          headers["Connection"].should == "Upgrade"
          headers["Upgrade"].should == "WebSocket"
          headers["Host"].to_s.should == "127.0.0.1:12345"
          handshake.path.should == "/"
          handshake.query.should == {}
          handshake.origin.should == "127.0.0.1"
        }
        ws.onclose {
          ws.state.should == :closed
          done
        }
      end
    }
  end

  it "should expose the WebSocket path and query params when nonempty" do
    em {
      EM.add_timer(0.1) do
        http = EM::HttpRequest.new('ws://127.0.0.1:12345/hello').get({
          :query => {'foo' => 'bar', 'baz' => 'qux'},
          :timeout => 0
        })
        http.errback { fail }
        http.callback {
          http.response_header.status.should == 101
          http.close_connection
        }
        http.stream { |msg| }
      end

      EM::WebSocket.start(:host => "0.0.0.0", :port => 12345) do |ws|
        ws.onopen { |handshake|
          handshake.path.should == '/hello'
          handshake.query_string.split('&').sort.
            should == ["baz=qux", "foo=bar"]
          handshake.query.should == {"foo"=>"bar", "baz"=>"qux"}
        }
        ws.onclose {
          ws.state.should == :closed
          done
        }
      end
    }
  end

  it "should raise an exception if frame sent before handshake complete" do
    em {
      # 1. Start WebSocket server
      EM::WebSocket.start(:host => "0.0.0.0", :port => 12345) { |ws|
        # 3. Try to send a message to the socket
        lambda {
          ws.send('early message')
        }.should raise_error('Cannot send data before onopen callback')
        done
      }

      # 2. Connect a dumb TCP connection (will not send handshake)
      EM.connect('0.0.0.0', 12345, EM::Connection)
    }
  end

  it "should allow the server to be started inside an existing EM" do
    em {
      EM.add_timer(0.1) do
        http = EM::HttpRequest.new('ws://127.0.0.1:12345/').get :timeout => 0
        http.errback { fail }
        http.callback {
          http.response_header.status.should == 101
          http.close_connection
        }
        http.stream { |msg| }
      end

      EM::WebSocket.run(:host => "0.0.0.0", :port => 12345) do |ws|
        ws.onopen { |handshake|
          handshake.headers["User-Agent"].should == "EventMachine HttpClient"
        }
        ws.onclose {
          ws.state.should == :closed
          done
        }
      end
    }
  end
end
