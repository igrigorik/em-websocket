require 'helper'

describe EM::WebSocket::MaskedString do
  it "should allow reading 4 byte mask and unmasking byte / bytes" do
    t = EM::WebSocket::MaskedString.new("\x00\x00\x00\x01\x00\x01\x00\x01")
    t.read_mask
    t.getbyte(3).should == 0x00
    t.getbytes(0, 4).should == "\x00\x01\x00\x00"
    t.getbytes(1, 3).should ==     "\x01\x00\x00"
  end
end
