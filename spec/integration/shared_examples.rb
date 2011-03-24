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
end
