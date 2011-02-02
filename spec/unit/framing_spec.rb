require 'helper'

describe EM::WebSocket::Framing03 do
  class FramingContainer
    include EM::WebSocket::Framing03
    
    def <<(data)
      @data << data
      process_data(data)
    end
    
    def debug(*args); end
  end
  
  before :each do
    @f = FramingContainer.new
    @f.initialize_framing
  end
  
  describe "basic examples" do
    it "connection close" do
      @f.should_receive(:message).with(:close, '', '')
      @f << 0b00000001
      @f << 0b00000000
    end
    
    it "ping" do
      @f.should_receive(:message).with(:ping, '', '')
      @f << 0b00000010
      @f << 0b00000000
    end
    
    it "pong" do
      @f.should_receive(:message).with(:pong, '', '')
      @f << 0b00000011
      @f << 0b00000000
    end
    
    it "text" do
      @f.should_receive(:message).with(:text, '', 'foo')
      @f << 0b00000100
      @f << 0b00000011
      @f << 'foo'
    end
    
    it "Text in two frames" do
      @f.should_receive(:message).with(:text, '', 'hello world')
      @f << 0b10000100
      @f << 0b00000110
      @f << "hello "
      @f << 0b00000000
      @f << 0b00000101
      @f << "world"
    end
    
    it "2 byte extended payload length text frame" do
      data = 'a' * 256
      @f.should_receive(:message).with(:text, '', data)
      @f << 0b00000100 # Single frame, text
      @f << 0b01111110 # Length 126 (so read 2 bytes)
      @f << 0b00000001 # Two bytes in network byte order (256)
      @f << 0b00000000
      @f << data
    end
  end
  
  # These examples are straight from the spec
  # http://tools.ietf.org/html/draft-ietf-hybi-thewebsocketprotocol-03#section-4.6
  describe "examples from the spec" do
    it "a single-frame text message" do
      @f.should_receive(:message).with(:text, '', 'Hello')
      @f << "\x04\x05Hello"
    end
    
    it "a fragmented text message" do
      @f.should_receive(:message).with(:text, '', 'Hello')
      @f << "\x84\x03Hel"
      @f << "\x00\x02lo"
    end
    
    it "Ping request and response" do
      @f.should_receive(:message).with(:ping, '', 'Hello')
      @f << "\x02\x05Hello"
    end
    
    it "256 bytes binary message in a single frame" do
      data = "a"*256
      @f.should_receive(:message).with(:binary, '', data)
      @f << "\x05\x7E\x01\x00" + data
    end
    
    it "64KiB binary message in a single frame" do
      data = "a"*65536
      @f.should_receive(:message).with(:binary, '', data)
      @f << "\x05\x7F\x00\x00\x00\x00\x00\x01\x00\x00" + data
    end
  end

  describe "error cases" do
    it "should raise an exception on continuation frame without preceeding more frame" do
      lambda {
        @f << 0b00000000 # Single frame, continuation
        @f << 0b00000001 # Length 1
        @f << 'f'
      }.should raise_error(EM::WebSocket::WebSocketError, 'Continuation frame not expected')
    end
  end
end
