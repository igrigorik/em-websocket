require 'helper'

describe "draft05" do
  include EM::SpecHelper
  default_timeout 1

  before :each do
    @request = {
      :port => 80,
      :method => "GET",
      :path => "/demo",
      :headers => {
        'Host' => 'example.com',
        'Upgrade' => 'websocket',
        'Connection' => 'Upgrade',
        'Sec-WebSocket-Key' => 'dGhlIHNhbXBsZSBub25jZQ==',
        'Sec-WebSocket-Protocol' => 'sample',
        'Sec-WebSocket-Origin' => 'http://example.com',
        'Sec-WebSocket-Version' => '5'
      }
    }
  end
  
  def start_server
    EM::WebSocket.start(:host => "0.0.0.0", :port => 12345) { |ws|
      yield ws
    }
  end

  def start_client
    client = EM.connect('0.0.0.0', 12345, Draft03FakeWebSocketClient)
    client.send_data(format_request(@request))
    yield client if block_given?
  end
  
  it "should open connection" do
    em {
      start_server { |server|
        server.onopen {
          server.instance_variable_get(:@handler).class.should == EventMachine::WebSocket::Handler05
          done
        }
      }
      
      start_client
    }
  end
end
