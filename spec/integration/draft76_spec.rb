require 'helper'

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

  it "should accept null bytes within the frame after a line return" do
    EM.run do
      EM.add_timer(0.1) do
        EventMachine::WebSocket.start(:host => "0.0.0.0", :port => 12345) { |ws|
          ws.onmessage { |msg|
            msg.should == "\n\000" 
          }
        }
  
        # Create a fake client which sends draft 76 handshake
        connection = EM.connect('0.0.0.0', 12345, FakeWebSocketClient)
        connection.send_data(format_request(@request))
  
        # Send closing frame after handshake complete
        connection.onopen = lambda {
          connection.send_data("\000\n\000\377")
          connection.send_data(EM::WebSocket::Handler76::TERMINATE_STRING)
        }
  
        connection.onclose = lambda {
          EM.stop
        }
      end
    end
  end

  it "should handle unreasonable frame lengths by calling onerror callback" do
    EM.run do
      EventMachine::WebSocket.start(:host => "0.0.0.0", :port => 12345) { |server|
        server.onerror { |error|
          error.should be_an_instance_of EM::WebSocket::DataError
          error.message.should == "Frame length too long (1180591620717411303296 bytes)"
          EM.stop
        }
      }

      # Create a fake client which sends draft 76 handshake
      client = EM.connect('0.0.0.0', 12345, FakeWebSocketClient)
      client.send_data(format_request(@request))

      # This particular frame indicates a message length of
      # 1180591620717411303296 bytes. Such a message would previously cause
      # a "bignum too big to convert into `long'" error.
      # However it is clearly unreasonable and should be rejected.
      client.onopen = lambda {
        client.send_data("\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\x00")
      }
    end
  end
  
  it "should handle impossible frames by calling onerror callback" do
    EM.run do
      EventMachine::WebSocket.start(:host => "0.0.0.0", :port => 12345) { |server|
        server.onerror { |error|
          error.should be_an_instance_of EM::WebSocket::DataError
          error.message.should == "Invalid frame received"
          EM.stop
        }
      }

      # Create a fake client which sends draft 76 handshake
      client = EM.connect('0.0.0.0', 12345, FakeWebSocketClient)
      client.send_data(format_request(@request))

      client.onopen = lambda {
        client.send_data("foobar") # Does not start with \x00 or \xff
      }
    end
  end

  it "should handle invalid http requests by raising HandshakeError passed to onerror callback" do
    EM.run {
      EventMachine::WebSocket.start(:host => "0.0.0.0", :port => 12345) { |server|
        server.onerror { |error|
          error.should be_an_instance_of EM::WebSocket::HandshakeError
          error.message.should == "Invalid HTTP header"
          EM.stop
        }
      }
      
      client = EM.connect('0.0.0.0', 12345, FakeWebSocketClient)
      client.send_data("This is not a HTTP header\r\n\r\n")
    }
  end

  it "should handle handshake request split into two TCP packets" do
    EM.run do
      EM.add_timer(0.1) do
        EventMachine::WebSocket.start(:host => "0.0.0.0", :port => 12345) { }

        # Create a fake client which sends draft 76 handshake
        connection = EM.connect('0.0.0.0', 12345, FakeWebSocketClient)
        data = format_request(@request)
        # Sends first half of the request
        connection.send_data(data[0...(data.length / 2)])

        connection.onopen = lambda {
          connection.handshake_response.lines.sort.
            should == format_response(@response).lines.sort
          EM.stop
        }

        EM.add_timer(0.1) do
          # Sends second half of the request
          connection.send_data(data[(data.length / 2)..-1])
        end
      end
    end
  end
end
