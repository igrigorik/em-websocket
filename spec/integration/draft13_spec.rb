require 'helper'
require 'integration/shared_examples'

describe "draft13" do
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
        'Sec-WebSocket-Version' => '13'
      }
    }

    @response = {
      :protocol => "HTTP/1.1 101 Switching Protocols\r\n",
      :headers => {
        "Upgrade" => "websocket",
        "Connection" => "Upgrade",
        "Sec-WebSocket-Accept" => "s3pPLMBiTxaQ9kYGzzhZRbK+xOo=",
      }
    }
  end

  it_behaves_like "a websocket server" do
    def start_server
      EM::WebSocket.start(:host => "0.0.0.0", :port => 12345) { |ws|
        yield ws
      }
    end

    def start_client
      client = EM.connect('0.0.0.0', 12345, Draft07FakeWebSocketClient)
      client.send_data(format_request(@request))
      yield client if block_given?
    end
  end

  it "should send back the correct handshake response" do
    em {
      EM.add_timer(0.1) do
        EventMachine::WebSocket.start(:host => "0.0.0.0", :port => 12345) { }
        
        # Create a fake client which sends draft 07 handshake
        connection = EM.connect('0.0.0.0', 12345, Draft07FakeWebSocketClient)
        connection.send_data(format_request(@request))
        
        connection.onopen {
          connection.handshake_response.lines.sort.
            should == format_response(@response).lines.sort
          done
        }
      end
    }
  end
end
