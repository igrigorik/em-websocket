require 'helper'

describe 'EM::WebSocket::Masking04' do
  class MaskingContainer
    include EM::WebSocket::Masking04
  end
  
  before :each do
    @m = MaskingContainer.new
  end
  
  it "should allow setting mask key and unmasking arbitrary byte" do
    @m.masking_key = "\x00\x00\x00\x00"
    @m.unmask('a', 2).should == 'a'
    
    @m.masking_key = "\x00\x00\x00\x01"
    @m.unmask("\x00", 0).should == "\x00"
    @m.unmask("\x01", 0).should == "\x01"
    @m.unmask("\x00", 3).should == "\x01"
    @m.unmask("\x01", 3).should == "\x00"
  end
  
  it "should allow unmasking arbitrary length strings given start pointer" do
    @m.masking_key = "\x00\x00\x00\x01"
    @m.unmask("\x00\x01\x00\x01", 0).should == "\x00\x01\x00\x00"
    @m.unmask("\x00\x01\x00", 1).should == "\x00\x01\x01"
  end
end
