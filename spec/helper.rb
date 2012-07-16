require 'rubygems'
require 'rspec'
require 'em-spec/rspec'
require 'pp'
require 'em-http'

require 'em-websocket'

RSpec.configure do |c|
  c.mock_with :rspec
end

class FakeWebSocketClient < EM::Connection
  attr_reader :handshake_response, :packets

  def onopen(&blk);     @onopen = blk;    end
  def onclose(&blk);    @onclose = blk;   end
  def onerror(&blk);    @onerror = blk;   end
  def onmessage(&blk);  @onmessage = blk; end

  def initialize
    @state = :new
    @packets = []
  end

  def receive_data(data)
    # puts "RECEIVE DATA #{data}"
    if @state == :new
      @handshake_response = data
      @onopen.call if @onopen
      @state = :open
    else
      @onmessage.call(data) if @onmessage
      @packets << data
    end
  end

  def send(data)
    send_data("\x00#{data}\xff")
  end

  def unbind
    @onclose.call if @onclose
  end
end

class Draft03FakeWebSocketClient < FakeWebSocketClient
  def send(application_data)
    frame = ''
    opcode = 4 # fake only supports text frames
    byte1 = opcode # since more, rsv1-3 are 0
    frame << byte1

    length = application_data.size
    if length <= 125
      byte2 = length # since rsv4 is 0
      frame << byte2
    elsif length < 65536 # write 2 byte length
      frame << 126
      frame << [length].pack('n')
    else # write 8 byte length
      frame << 127
      frame << [length >> 32, length & 0xFFFFFFFF].pack("NN")
    end

    frame << application_data

    send_data(frame)
  end
end

class Draft07FakeWebSocketClient < FakeWebSocketClient
  def send(application_data)
    frame = ''
    opcode = 1 # fake only supports text frames
    byte1 = opcode | 0b10000000 # since more, rsv1-3 are 0
    frame << byte1

    length = application_data.size
    if length <= 125
      byte2 = length # since rsv4 is 0
      frame << byte2
    elsif length < 65536 # write 2 byte length
      frame << 126
      frame << [length].pack('n')
    else # write 8 byte length
      frame << 127
      frame << [length >> 32, length & 0xFFFFFFFF].pack("NN")
    end

    frame << application_data

    send_data(frame)
  end
end


# Wrap EM:HttpRequest in a websocket like interface so that it can be used in the specs with the same interface as FakeWebSocketClient
class Draft75WebSocketClient
  def onopen(&blk);     @onopen = blk;    end
  def onclose(&blk);    @onclose = blk;   end
  def onerror(&blk);    @onerror = blk;   end
  def onmessage(&blk);  @onmessage = blk; end

  def initialize
    @ws = EventMachine::HttpRequest.new('ws://127.0.0.1:12345/').get({
      :timeout => 0,
      :origin => 'http://example.com',
    })
    @ws.errback { @onerror.call if @onerror }
    @ws.callback { @onopen.call if @onopen }
    @ws.stream { |msg| @onmessage.call(msg) if @onmessage }
    @ws.disconnect { @onclose.call if @onclose }
  end

  def send(message)
    @ws.send(message)
  end

  def close_connection
    @ws.close_connection
  end
end

def format_request(r)
  data = "#{r[:method]} #{r[:path]} HTTP/1.1\r\n"
  header_lines = r[:headers].map { |k,v| "#{k}: #{v}" }
  data << [header_lines, '', r[:body]].join("\r\n")
  data
end

def format_response(r)
  data = r[:protocol] || "HTTP/1.1 101 WebSocket Protocol Handshake\r\n"
  header_lines = r[:headers].map { |k,v| "#{k}: #{v}" }
  data << [header_lines, '', r[:body]].join("\r\n")
  data
end

RSpec::Matchers.define :succeed_with_upgrade do |response|
  match do |actual|
    success = nil
    actual.callback { |upgrade_response, handler_klass|
      success = (upgrade_response.lines.sort == format_response(response).lines.sort)
    }
    success
  end
end

RSpec::Matchers.define :fail_with_error do |error_klass, error_message|
  match do |actual|
    success = nil
    actual.errback { |e|
      success = (e.class == error_klass)
      success &= (e.message == error_message) if error_message
    }
    success
  end
end
