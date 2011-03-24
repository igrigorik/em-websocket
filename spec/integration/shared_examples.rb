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
end
