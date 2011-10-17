require 'helper'

describe "draft06" do
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
        'Sec-WebSocket-Version' => '6'
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
          server.instance_variable_get(:@handler).class.should == EventMachine::WebSocket::Handler06
        }
      }
      
      start_client { |client|
        client.onopen {
          client.handshake_response.lines.sort.
            should == format_response(@response).lines.sort
          done
        }
      }
    }
  end
  
  it "should accept a single-frame text message (masked)" do
    em {
      start_server { |server|
        server.onmessage { |msg|
          msg.should == 'Hello'
          if msg.respond_to?(:encoding)
            msg.encoding.should == Encoding.find("UTF-8")
          end
          done
        }
        server.onerror {
          fail
        }
      }
  
      start_client { |client|
        client.onopen {
          client.send_data("\x00\x00\x01\x00\x84\x05Ielln")
        }
      }
    }
  end
end
