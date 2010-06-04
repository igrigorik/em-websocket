require 'spec/helper'

#  Sample request/response are from pywebsocket spec http://code.google.com/p/pywebsocket/

GOOD_RESPONSE_SECURE = [
  'HTTP/1.1 101 WebSocket Protocol Handshake\r\n',
  'Upgrade: WebSocket\r\n',
  'Connection: Upgrade\r\n',
  'Sec-WebSocket-Location: wss://example.com/demo\r\n',
  'Sec-WebSocket-Origin: http://example.com\r\n',
  'Sec-WebSocket-Protocol: sample\r\n',
  '\r\n',
  '8jKS\'y:G*Co,Wxa-'
]

GOOD_RESPONSE_SECURE_NONDEF = [
  'HTTP/1.1 101 WebSocket Protocol Handshake\r\n',
  'Upgrade: WebSocket\r\n',
  'Connection: Upgrade\r\n',
  'Sec-WebSocket-Location: wss://example.com:8081/demo\r\n',
  'Sec-WebSocket-Origin: http://example.com\r\n',
  'Sec-WebSocket-Protocol: sample\r\n',
  '\r\n',
  '8jKS\'y:G*Co,Wxa-'
]

BAD_REQUESTS = [
    [  # HTTP request
        80,
        'GET',
        '/demo',
        {
            'Host' => 'www.google.com',
            'User-Agent' => ['Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.5;',
                         ' en-US; rv:1.9.1.3) Gecko/20090824 Firefox/3.5.3',
                         ' GTB6 GTBA'],
            'Accept' => ['text/html,application/xhtml+xml,application/xml;q=0.9,',
                     '*/*;q=0.8'],
            'Accept-Language' => 'en-us,en;q=0.5',
            'Accept-Encoding' => 'gzip,deflate',
            'Accept-Charset' => 'ISO-8859-1,utf-8;q=0.7,*;q=0.7',
            'Keep-Alive' => '300',
            'Connection' => 'keep-alive',
        }
    ],
    [  # Wrong method
        80,
        'POST',
        '/demo',
        {
            'Host' => 'example.com',
            'Connection' => 'Upgrade',
            'Sec-WebSocket-Key2' => '12998 5 Y3 1  .P00',
            'Sec-WebSocket-Protocol' => 'sample',
            'Upgrade' => 'WebSocket',
            'Sec-WebSocket-Key1' => '4 @1  46546xW%0l 1 5',
            'Origin' => 'http://example.com',
        },
        '^n:ds[4U'
    ],
    [  # Missing Upgrade
        80,
        'GET',
        '/demo',
        {
            'Host' => 'example.com',
            'Connection' => 'Upgrade',
            'Sec-WebSocket-Key2' => '12998 5 Y3 1  .P00',
            'Sec-WebSocket-Protocol' => 'sample',
            'Sec-WebSocket-Key1' => '4 @1  46546xW%0l 1 5',
            'Origin' => 'http://example.com',
        },
        '^n:ds[4U'
    ],
    [  # Wrong Upgrade
        80,
        'GET',
        '/demo',
        {
            'Host' => 'example.com',
            'Connection' => 'Upgrade',
            'Sec-WebSocket-Key2' => '12998 5 Y3 1  .P00',
            'Sec-WebSocket-Protocol' => 'sample',
            'Upgrade' => 'NonWebSocket',
            'Sec-WebSocket-Key1' => '4 @1  46546xW%0l 1 5',
            'Origin' => 'http://example.com',
        },
        '^n:ds[4U'
    ],
    [  # Empty WebSocket-Protocol
        80,
        'GET',
        '/demo',
        {
            'Host' => 'example.com',
            'Connection' => 'Upgrade',
            'Sec-WebSocket-Key2' => '12998 5 Y3 1  .P00',
            'Sec-WebSocket-Protocol' => '',
            'Upgrade' => 'WebSocket',
            'Sec-WebSocket-Key1' => '4 @1  46546xW%0l 1 5',
            'Origin' => 'http://example.com',
        },
        '^n:ds[4U'
    ],
    [  # Wrong port number format
        80,
        'GET',
        '/demo',
        {
            'Host' => 'example.com:0x50',
            'Connection' => 'Upgrade',
            'Sec-WebSocket-Key2' => '12998 5 Y3 1  .P00',
            'Sec-WebSocket-Protocol' => 'sample',
            'Upgrade' => 'WebSocket',
            'Sec-WebSocket-Key1' => '4 @1  46546xW%0l 1 5',
            'Origin' => 'http://example.com',
        },
        '^n:ds[4U'
    ],
    [  # Header/connection port mismatch
        8080,
        'GET',
        '/demo',
        {
            'Host' => 'example.com',
            'Connection' => 'Upgrade',
            'Sec-WebSocket-Key2' => '12998 5 Y3 1  .P00',
            'Sec-WebSocket-Protocol' => 'sample',
            'Upgrade' => 'WebSocket',
            'Sec-WebSocket-Key1' => '4 @1  46546xW%0l 1 5',
            'Origin' => 'http://example.com',
        },
        '^n:ds[4U'
    ],
    [  # Illegal WebSocket-Protocol
        80,
        'GET',
        '/demo',
        {
            'Host' => 'example.com',
            'Connection' => 'Upgrade',
            'Sec-WebSocket-Key2' => '12998 5 Y3 1  .P00',
            'Sec-WebSocket-Protocol' => 'illegal\x09protocol',
            'Upgrade' => 'WebSocket',
            'Sec-WebSocket-Key1' => '4 @1  46546xW%0l 1 5',
            'Origin' => 'http://example.com',
        },
        '^n:ds[4U'
    ],
]

describe "EventMachine::WebSocket::RequestHandler" do
  def format_request(r)
    data = "#{r[:method]} #{r[:path]} HTTP/1.1\r\n"
    header_lines = r[:headers].map { |k,v| "#{k}: #{v}" }
    data << [header_lines, '', r[:body]].join("\r\n")
    data
  end

  def format_response(r)
    data = "HTTP/1.1 101 WebSocket Protocol Handshake\r\n"
    header_lines = r[:headers].map { |k,v| "#{k}: #{v}" }
    data << [header_lines, '', r[:body]].join("\r\n")
    data
  end

  def handler(request)
    handler = EventMachine::WebSocket::RequestHandler.new
    handler.parse(format_request(request))
    handler
  end
  
  def send_handshake(response)
    simple_matcher do |given|
      given.response.sort == format_response(response).sort
    end
  end

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

  it "should handle good request" do
    handler(@request).should send_handshake(@response)
  end

  it "should handle good request to secure default port" do
    pending "No SSL support yet"
  end

  it "should handle good request on nondefault port" do
    @request[:port] = 8081
    @request[:headers]['Host'] = 'example.com:8081'
    @response[:headers]['Sec-WebSocket-Location'] =
      'ws://example.com:8081/demo'

    handler(@request).should send_handshake(@response)
  end

  it "should handle good request to secure nondefault port" do
    pending "No SSL support yet"
  end

  it "should handle good request with no protocol" do
    @request[:headers].delete('Sec-WebSocket-Protocol')
    @response[:headers].delete("Sec-WebSocket-Protocol")

    handler(@request).should send_handshake(@response)
  end

  it "should handle extra headers by simply ignoring them" do
    @request[:headers]['EmptyValue'] = ""
    @request[:headers]['AKey'] = "AValue"

    handler(@request).should send_handshake(@response)
  end
  
  it "should raise error on HTTP request" do
    @request[:headers] = {
      'Host' => 'www.google.com',
      'User-Agent' => 'Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.5; en-US; rv:1.9.1.3) Gecko/20090824 Firefox/3.5.3 GTB6 GTBA',
      'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      'Accept-Language' => 'en-us,en;q=0.5',
      'Accept-Encoding' => 'gzip,deflate',
      'Accept-Charset' => 'ISO-8859-1,utf-8;q=0.7,*;q=0.7',
      'Keep-Alive' => '300',
      'Connection' => 'keep-alive',
    }
    
    lambda {
      handler(@request).response
    }.should raise_error(EM::WebSocket::HandshakeError)
  end
end
