# encoding: UTF-8

shared_examples_for "a websocket server" do
  it "should call onerror if an application error raised in onopen" do
    EM.run {
      start_server { |ws|
        ws.onopen {
          raise "application error"
        }

        ws.onerror { |e|
          e.message.should == "application error"
          EM.stop
        }
      }

      start_client
    }
  end

  it "should call onerror if an application error raised in onmessage" do
    EM.run {
      start_server { |server|
        server.onmessage {
          raise "application error"
        }

        server.onerror { |e|
          e.message.should == "application error"
          EM.stop
        }
      }

      start_client { |client|
        client.onopen {
          client.send('a message')
        }
      }
    }
  end

  it "should call onerror in an application error raised in onclose" do
    EM.run {
      start_server { |server|
        server.onclose {
          raise "application error"
        }

        server.onerror { |e|
          e.message.should == "application error"
          EM.stop
        }
      }

      start_client { |client|
        client.onopen {
          EM.add_timer(0.1) {
            client.close_connection
          }
        }
      }
    }
  end

  # Only run these tests on ruby 1.9
  if "a".respond_to?(:force_encoding)
    it "should raise error if you try to send non utf8 text data to ws" do
      EM.run do
        start_server { |server|
          server.onopen {
            # Create a string which claims to be UTF-8 but which is not
            s = "ê" # utf-8 string
            s.encode!("ISO-8859-1")
            s.force_encoding("UTF-8")
            s.valid_encoding?.should == false # now invalid utf8

            # Send non utf8 encoded data
            server.send(s)
          }
          server.onerror { |error|
            error.class.should == EventMachine::WebSocket::WebSocketError
            error.message.should == "Data sent to WebSocket must be valid UTF-8 but was UTF-8 (valid: false)"
            EM.stop
          }
        }

        start_client { }
      end
    end
  end
end
