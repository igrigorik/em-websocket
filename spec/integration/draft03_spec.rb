require 'helper'

describe "draft03" do
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
        'Origin' => 'http://example.com',
        'Sec-WebSocket-Draft' => '3'
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

  # These examples are straight from the spec
  # http://tools.ietf.org/html/draft-ietf-hybi-thewebsocketprotocol-03#section-4.6
  describe "examples from the spec" do
    it "should accept a single-frame text message" do
      EM.run do
        EM::WebSocket.start(:host => "0.0.0.0", :port => 12345) { |ws|
          ws.onmessage { |msg|
            msg.should == 'Hello'
            EM.stop
          }
        }

        # Create a fake client which sends draft 76 handshake
        connection = EM.connect('0.0.0.0', 12345, FakeWebSocketClient)
        connection.send_data(format_request(@request))

        # Send frame
        connection.onopen = lambda {
          connection.send_data("\x04\x05Hello")
        }
      end
    end
    
    it "should accept a fragmented text message" do
      EM.run do
        EM::WebSocket.start(:host => "0.0.0.0", :port => 12345) { |ws|
          ws.onmessage { |msg|
            msg.should == 'Hello'
            EM.stop
          }
        }

        # Create a fake client which sends draft 76 handshake
        connection = EM.connect('0.0.0.0', 12345, FakeWebSocketClient)
        connection.send_data(format_request(@request))

        # Send frame
        connection.onopen = lambda {
          connection.send_data("\x84\x03Hel")
          connection.send_data("\x00\x02lo")
        }
      end
    end
    
    it "should accept a ping request and respond with the same body" do
      EM.run do
        EM::WebSocket.start(:host => "0.0.0.0", :port => 12345) { |ws| }

        # Create a fake client which sends draft 76 handshake
        connection = EM.connect('0.0.0.0', 12345, FakeWebSocketClient)
        connection.send_data(format_request(@request))

        # Send frame
        connection.onopen = lambda {
          connection.send_data("\x02\x05Hello")
        }
        
        connection.onmessage = lambda { |frame|
          next if frame.nil?
          frame.should == "\x03\x05Hello"
          EM.stop
        }
      end
    end
    
    it "should accept a 256 bytes binary message in a single frame" do
      EM.run do
        data = "a" * 256
        
        EM::WebSocket.start(:host => "0.0.0.0", :port => 12345) { |ws|
          ws.onmessage { |msg|
            msg.should == data
            EM.stop
          }
        }

        # Create a fake client which sends draft 76 handshake
        connection = EM.connect('0.0.0.0', 12345, FakeWebSocketClient)
        connection.send_data(format_request(@request))

        # Send frame
        connection.onopen = lambda {
          connection.send_data("\x05\x7E\x01\x00" + data)
        }
      end
    end
    
    it "should accept a 64KiB binary message in a single frame" do
      EM.run do
        data = "a" * 65536
        
        EM::WebSocket.start(:host => "0.0.0.0", :port => 12345) { |ws|
          ws.onmessage { |msg|
            msg.should == data
            EM.stop
          }
        }

        # Create a fake client which sends draft 76 handshake
        connection = EM.connect('0.0.0.0', 12345, FakeWebSocketClient)
        connection.send_data(format_request(@request))

        # Send frame
        connection.onopen = lambda {
          connection.send_data("\x05\x7F\x00\x00\x00\x00\x00\x01\x00\x00" + data)
        }
      end
    end
  end

  describe "close handling" do
    it "should respond to a new close frame with a close frame" do
      EM.run do
        EM::WebSocket.start(:host => "0.0.0.0", :port => 12345) { |ws| }

        # Create a fake client which sends draft 76 handshake
        connection = EM.connect('0.0.0.0', 12345, FakeWebSocketClient)
        connection.send_data(format_request(@request))

        # Send close frame
        connection.onopen = lambda {
          connection.send_data("\x01\x00")
        }

        # Check that close ack received
        connection.onmessage = lambda { |frame|
          frame.should == "\x01\x00"
          EM.stop
        }
      end
    end

    it "should close the connection on receiving a close acknowlegement" do
      EM.run do
        ack_received = false

        EM::WebSocket.start(:host => "0.0.0.0", :port => 12345) { |ws|
          ws.onopen {
            # 2. Send a close frame
            EM.next_tick {
              ws.close_websocket
            }
          }
        }

        # 1. Create a fake client which sends draft 76 handshake
        connection = EM.connect('0.0.0.0', 12345, FakeWebSocketClient)
        connection.send_data(format_request(@request))

        # 3. Check that close frame recieved and acknowlege it
        connection.onmessage = lambda { |frame|
          frame.should == "\x01\x00"
          ack_received = true
          connection.send_data("\x01\x00")
        }

        # 4. Check that connection is closed _after_ the ack
        connection.onclose = lambda {
          ack_received.should == true
          EM.stop
        }
      end
    end

    it "should not allow data frame to be sent after close frame sent" do
      EM.run {
        EM::WebSocket.start(:host => "0.0.0.0", :port => 12345) { |ws|
          ws.onopen {
            # 2. Send a close frame
            EM.next_tick {
              ws.close_websocket
            }

            # 3. Check that exception raised if I attempt to send more data
            EM.add_timer(0.1) {
              lambda {
                ws.send('hello world')
              }.should raise_error(EM::WebSocket::WebSocketError, 'Cannot send data frame since connection is closing')
              EM.stop
            }
          }
        }

        # 1. Create a fake client which sends draft 76 handshake
        connection = EM.connect('0.0.0.0', 12345, FakeWebSocketClient)
        connection.send_data(format_request(@request))
      }
    end

    it "should still respond to control frames after close frame sent" do
      EM.run {
        EM::WebSocket.start(:host => "0.0.0.0", :port => 12345) { |ws|
          ws.onopen {
            # 2. Send a close frame
            EM.next_tick {
              ws.close_websocket
            }
          }
        }

        # 1. Create a fake client which sends draft 76 handshake
        connection = EM.connect('0.0.0.0', 12345, FakeWebSocketClient)
        connection.send_data(format_request(@request))

        connection.onmessage = lambda { |frame|
          if frame == "\x01\x00"
            # 3. After the close frame is received send a ping frame, but
            # don't respond with a close ack
            connection.send_data("\x02\x05Hello")
          else
            # 4. Check that the pong is received
            frame.should == "\x03\x05Hello"
            EM.stop
          end
        }
      }
    end
  end
end
