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
    '8jKS\'y:G*Co,Wxa-']

GOOD_REQUEST_NONDEFAULT_PORT = [
    8081,
    'GET',
    '/demo',
    {
        'Host' => 'example.com:8081',
        'Connection' => 'Upgrade',
        'Sec-WebSocket-Key2' => '12998 5 Y3 1  .P00',
        'Sec-WebSocket-Protocol' => 'sample',
        'Upgrade' => 'WebSocket',
        'Sec-WebSocket-Key1' => '4 @1  46546xW%0l 1 5',
        'Origin' => 'http://example.com',
    },
    '^n:ds[4U'
]

GOOD_RESPONSE_NONDEFAULT_PORT = [
    'HTTP/1.1 101 WebSocket Protocol Handshake\r\n',
    'Upgrade: WebSocket\r\n',
    'Connection: Upgrade\r\n',
    'Sec-WebSocket-Location: ws://example.com:8081/demo\r\n',
    'Sec-WebSocket-Origin: http://example.com\r\n',
    'Sec-WebSocket-Protocol: sample\r\n',
    '\r\n',
    '8jKS\'y:G*Co,Wxa-']

GOOD_RESPONSE_SECURE_NONDEF = [
    'HTTP/1.1 101 WebSocket Protocol Handshake\r\n',
    'Upgrade: WebSocket\r\n',
    'Connection: Upgrade\r\n',
    'Sec-WebSocket-Location: wss://example.com:8081/demo\r\n',
    'Sec-WebSocket-Origin: http://example.com\r\n',
    'Sec-WebSocket-Protocol: sample\r\n',
    '\r\n',
    '8jKS\'y:G*Co,Wxa-']

GOOD_REQUEST_NO_PROTOCOL = [
    80,
    'GET',
    '/demo',
    {
        'Host' => 'example.com',
        'Connection' => 'Upgrade',
        'Sec-WebSocket-Key2' => '12998 5 Y3 1  .P00',
        'Upgrade' => 'WebSocket',
        'Sec-WebSocket-Key1' => '4 @1  46546xW%0l 1 5',
        'Origin' => 'http://example.com',
    },
    '^n:ds[4U'
]

GOOD_RESPONSE_NO_PROTOCOL = [
    'HTTP/1.1 101 WebSocket Protocol Handshake\r\n',
    'Upgrade: WebSocket\r\n',
    'Connection: Upgrade\r\n',
    'Sec-WebSocket-Location: ws://example.com/demo\r\n',
    'Sec-WebSocket-Origin: http://example.com\r\n',
    '\r\n',
    '8jKS\'y:G*Co,Wxa-']

GOOD_REQUEST_WITH_OPTIONAL_HEADERS = [
    80,
    'GET',
    '/demo',
    {
        'Host' => 'example.com',
        'Connection' => 'Upgrade',
        'Sec-WebSocket-Key2' => '12998 5 Y3 1  .P00',
        'EmptyValue' => '',
        'Sec-WebSocket-Protocol' => 'sample',
        'AKey' => 'AValue',
        'Upgrade' => 'WebSocket',
        'Sec-WebSocket-Key1' => '4 @1  46546xW%0l 1 5',
        'Origin' => 'http://example.com',
    },
    '^n:ds[4U'
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

describe "RequestHandlerSpec" do
  it "should handle good request" do
    GOOD_REQUEST = [
            'GET /demo HTTP/1.1',
            'Host: example.com',
            'Connection: Upgrade',
            'Sec-WebSocket-Key2: 12998 5 Y3 1  .P00',
            'Sec-WebSocket-Protocol: sample',
            'Upgrade: WebSocket',
            'Sec-WebSocket-Key1: 4 @1  46546xW%0l 1 5',
            'Origin: http://example.com',
            '\r\n',
            '^n:ds[4U',
    ]

    GOOD_RESPONSE_DEFAULT_PORT = [
        'HTTP/1.1 101 WebSocket Protocol Handshake\r\n',
        'Upgrade: WebSocket\r\n',
        'Connection: Upgrade\r\n',
        'Sec-WebSocket-Location: ws://example.com/demo\r\n',
        'Sec-WebSocket-Origin: http://example.com\r\n',
        'Sec-WebSocket-Protocol: sample\r\n',
        '\r\n',
        '8jKS\'y:G*Co,Wxa-']
        
    good_request = EventMachine::WebSocket::RequestHandler.new
    good_request.parse(GOOD_REQUEST)

    good_request.response.should == GOOD_RESPONSE_DEFAULT_PORT.join
    # good_request.ws_resource.should == '/demo'
    # good_request.ws_origin.should == 'http://example.com'
    # good_request.ws_location.should == 'ws://example.com/demo'
    # good_request.ws_protocol.should == 'sample'
  end
end