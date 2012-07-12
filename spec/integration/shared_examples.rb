# encoding: UTF-8

# These tests are run against all draft versions
#
shared_examples_for "a websocket server" do
  it "should expose the protocol version" do
    em {
      start_server { |ws|
        ws.onopen { |handshake|
          handshake.protocol_version.should == version
          done
        }
      }

      start_client
    }
  end

  it "should expose the origin header" do
    em {
      start_server { |ws|
        ws.onopen { |handshake|
          handshake.origin.should == 'http://example.com'
          done
        }
      }

      start_client
    }
  end

  it "should call onerror if an application error raised in onopen" do
    em {
      start_server { |ws|
        ws.onopen {
          raise "application error"
        }

        ws.onerror { |e|
          e.message.should == "application error"
          done
        }
      }

      start_client
    }
  end

  it "should call onerror if an application error raised in onmessage" do
    em {
      start_server { |server|
        server.onmessage {
          raise "application error"
        }

        server.onerror { |e|
          e.message.should == "application error"
          done
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
    em {
      start_server { |server|
        server.onclose {
          raise "application error"
        }

        server.onerror { |e|
          e.message.should == "application error"
          done
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

  it "should close the connection when a too long frame is sent" do
    em {
      start_server { |server|
        server.max_frame_size = 20

        server.onerror { |e|
          # 3: Error should be reported to server
          e.class.should == EventMachine::WebSocket::WSMessageTooBigError
          e.message.should =~ /Frame length too long/
        }
      }

      start_client { |client|
        client.onopen {
          EM.next_tick {
            client.send("This message is longer than 20 characters")
          }

        }

        client.onmessage { |msg|
          # 4: This is actually the close message. Really need to use a real
          # WebSocket client in these tests...
          done
        }

        client.onclose {
          # 4: Drafts 75 & 76 don't send a close message, they just close the
          # connection
          done
        }
      }
    }
  end

  # Only run these tests on ruby 1.9
  if "a".respond_to?(:force_encoding)
    it "should raise error if you try to send non utf8 text data to ws" do
      em {
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
            done
          }
        }

        start_client { }
      }
    end

    it "should not change the encoding of strings sent to send [antiregression]" do
      em {
        start_server { |server|
          server.onopen {
            s = "example string"
            s.force_encoding("UTF-8")

            server.send(s)

            s.encoding.should == Encoding.find("UTF-8")
            done
          }
        }

        start_client { }
      }
    end
  end
end
