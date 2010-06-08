require 'spec/helper'

describe "WebSocket server draft76" do
  before :each do
    @request = {
      :port => 80,
      :method => "GET",
      :path => "/demo",
      :headers => {
        'Host' => 'example.com',
        'Connection' => 'Upgrade',
        'Sec-WebSocket-Key2' => '12998 5 Y3 1  .P00',
        'Sec-WebSocket-Protocol' => 'sample',
        'Upgrade' => 'WebSocket',
        'Sec-WebSocket-Key1' => '4 @1  46546xW%0l 1 5',
        'Origin' => 'http://example.com'
      },
      :body => '^n:ds[4U'
    }

    @response = {
      :headers => {
        "Upgrade" => "WebSocket",
        "Connection" => "Upgrade",
        "Sec-WebSocket-Location" => "ws://example.com/demo",
        "Sec-WebSocket-Origin" => "http://example.com",
        "Sec-WebSocket-Protocol" => "sample"
      },
      :body => "8jKS\'y:G*Co,Wxa-"
    }
  end
  
  it "should send back the correct handshake response" do
    EM.run do
      EM.add_timer(0.1) do
        EventMachine::WebSocket.start(:host => "0.0.0.0", :port => 12345) { }
        
        # Create a fake client which sends draft 76 handshake
        connection = EM.connect('0.0.0.0', 12345, FakeWebSocketClient)
        connection.send_data(format_request(@request))
        
        connection.onopen = lambda {
          connection.handshake_response.lines.sort.
            should == format_response(@response).lines.sort
          EM.stop
        }
      end
    end
  end
  
  it "should send closing frame back and close the connection after recieving closing frame" do
    EM.run do
      EM.add_timer(0.1) do
        EventMachine::WebSocket.start(:host => "0.0.0.0", :port => 12345) { }
  
        # Create a fake client which sends draft 76 handshake
        connection = EM.connect('0.0.0.0', 12345, FakeWebSocketClient)
        connection.send_data(format_request(@request))
  
        # Send closing frame after handshake complete
        connection.onopen = lambda {
          connection.send_data(EM::WebSocket::Handler76::TERMINATE_STRING)
        }
  
        # Check that this causes a termination string to be returned and the 
        # connection close
        connection.onclose = lambda {
          connection.packets[0].should == 
            EM::WebSocket::Handler76::TERMINATE_STRING
          EM.stop
        }
      end
    end
  end
  
  it "should ignore any data received after the closing frame" do
    EM.run do
      EM.add_timer(0.1) do
        EventMachine::WebSocket.start(:host => "0.0.0.0", :port => 12345) { |ws|
          # Fail if foobar message is received
          ws.onmessage { |msg|
            failed
          }
        }
        
        # Create a fake client which sends draft 76 handshake
        connection = EM.connect('0.0.0.0', 12345, FakeWebSocketClient)
        connection.send_data(format_request(@request))
  
        # Send closing frame after handshake complete, followed by another msg
        connection.onopen = lambda {
          connection.send_data(EM::WebSocket::Handler76::TERMINATE_STRING)
          connection.send('foobar')
        }
  
        connection.onclose = lambda {
          EM.stop
        }
      end
    end
  end
end
