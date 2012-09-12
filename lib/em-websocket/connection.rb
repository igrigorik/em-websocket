require 'addressable/uri'

module EventMachine
  module WebSocket
    class Connection < EventMachine::Connection
      include Debugger

      attr_writer :max_frame_size

      # define WebSocket callbacks
      def onopen(&blk);     @onopen = blk;    end
      def onclose(&blk);    @onclose = blk;   end
      def onerror(&blk);    @onerror = blk;   end
      def onmessage(&blk);  @onmessage = blk; end
      def onping(&blk);     @onping = blk;    end
      def onpong(&blk);     @onpong = blk;    end

      def trigger_on_message(msg)
        @onmessage.call(msg) if @onmessage
      end
      def trigger_on_open
        @onopen.call if @onopen
      end
      def trigger_on_close
        @onclose.call if @onclose
      end
      def trigger_on_ping(data)
        @onping.call(data) if @onping
      end
      def trigger_on_pong(data)
        @onpong.call(data) if @onpong
      end
      def trigger_on_error(reason)
        return false unless @onerror
        @onerror.call(reason)
        true
      end

      def initialize(options)
        @options = options
        @debug = options[:debug] || false
        @secure = options[:secure] || false
        @secure_proxy = options[:secure_proxy] || false
        @tls_options = options[:tls_options] || {}
        @data = ''

        debug [:initialize]
      end

      # Use this method to close the websocket connection cleanly
      # This sends a close frame and waits for acknowlegement before closing
      # the connection
      def close_websocket(code = nil, body = nil)
        if code && !(4000..4999).include?(code)
          raise "Application code may only use codes in the range 4000-4999"
        end

        # If code not defined then set to 1000 (normal closure)
        code ||= 1000

        close_websocket_private(code, body)
      end

      def post_init
        start_tls(@tls_options) if @secure
      end

      def receive_data(data)
        debug [:receive_data, data]

        if @handler
          @handler.receive_data(data)
        else
          dispatch(data)
        end
      rescue HandshakeError => e
        debug [:error, e]
        trigger_on_error(e)
        # Errors during the handshake require the connection to be aborted
        abort
      rescue WSProtocolError => e
        debug [:error, e]
        trigger_on_error(e)
        close_websocket_private(e.code)
      rescue => e
        debug [:error, e]
        # These are application errors - raise unless onerror defined
        trigger_on_error(e) || raise(e)
        # There is no code defined for application errors, so use 3000
        # (which is reserved for frameworks)
        close_websocket_private(3000)
      end

      def unbind
        debug [:unbind, :connection]

        @handler.unbind if @handler
      rescue => e
        debug [:error, e]
        # These are application errors - raise unless onerror defined
        trigger_on_error(e) || raise(e)
      end

      def dispatch(data)
        if data.match(/\A<policy-file-request\s*\/>/)
          send_flash_cross_domain_file
          return false
        else
          debug [:inbound_headers, data]
          @data << data
          @handler = HandlerFactory.build(self, @data, @secure || @secure_proxy, @debug)
          unless @handler
            # The whole header has not been received yet.
            return false
          end
          @data = nil
          @handler.run
          return true
        end
      end

      def send_flash_cross_domain_file
        file =  '<?xml version="1.0"?><cross-domain-policy><allow-access-from domain="*" to-ports="*"/></cross-domain-policy>'
        debug [:cross_domain, file]
        send_data file

        # handle the cross-domain request transparently
        # no need to notify the user about this connection
        @onclose = nil
        close_connection_after_writing
      end

      # Cache encodings since it's moderately expensive to look them up each time
      ENCODING_SUPPORTED = "string".respond_to?(:force_encoding)
      UTF8 = Encoding.find("UTF-8") if ENCODING_SUPPORTED
      BINARY = Encoding.find("BINARY") if ENCODING_SUPPORTED

      # Send a WebSocket text frame.
      #
      # A WebSocketError may be raised if the connection is in an opening or a
      # closing state, or if the passed in data is not valid UTF-8
      #
      def send(data)
        # If we're using Ruby 1.9, be pedantic about encodings
        if ENCODING_SUPPORTED
          # Also accept ascii only data in other encodings for convenience
          unless (data.encoding == UTF8 && data.valid_encoding?) || data.ascii_only?
            raise WebSocketError, "Data sent to WebSocket must be valid UTF-8 but was #{data.encoding} (valid: #{data.valid_encoding?})"
          end
          # This labels the encoding as binary so that it can be combined with
          # the BINARY framing
          data.force_encoding(BINARY)
        else
          # TODO: Check that data is valid UTF-8
        end

        if @handler
          @handler.send_text_frame(data)
        else
          raise WebSocketError, "Cannot send data before onopen callback"
        end

        # Revert data back to the original encoding (which we assume is UTF-8)
        # Doing this to avoid duping the string - there may be a better way
        data.force_encoding(UTF8) if ENCODING_SUPPORTED
        return nil
      end

      # Send a WebSocket binary frame.
      #
      def send_binary(data)
        if @handler
          @handler.send_frame(:binary, data)
        else
          raise WebSocketError, "Cannot send binary before onopen callback"
        end
      end

      # Send a ping to the client. The client must respond with a pong.
      #
      # In the case that the client is running a WebSocket draft < 01, false
      # is returned since ping & pong are not supported
      #
      def ping(body = '')
        if @handler
          @handler.pingable? ? @handler.send_frame(:ping, body) && true : false
        else
          raise WebSocketError, "Cannot ping before onopen callback"
        end
      end

      # Send an unsolicited pong message, as allowed by the protocol. The
      # client is not expected to respond to this message.
      #
      # em-websocket automatically takes care of sending pong replies to
      # incoming ping messages, as the protocol demands.
      #
      def pong(body = '')
        if @handler
          @handler.pingable? ? @handler.send_frame(:pong, body) && true : false
        else
          raise WebSocketError, "Cannot ping before onopen callback"
        end
      end

      # Test whether the connection is pingable (i.e. the WebSocket draft in
      # use is >= 01)
      def pingable?
        if @handler
          @handler.pingable?
        else
          raise WebSocketError, "Cannot test whether pingable before onopen callback"
        end
      end

      def request
        @handler ? @handler.request : {}
      end

      def state
        @handler ? @handler.state : :handshake
      end

      # Returns the maximum frame size which this connection is configured to
      # accept. This can be set globally or on a per connection basis, and
      # defaults to a value of 10MB if not set.
      #
      # The behaviour when a too large frame is received varies by protocol,
      # but in the newest protocols the connection will be closed with the
      # correct close code (1009) immediately after receiving the frame header
      #
      def max_frame_size
        @max_frame_size || WebSocket.max_frame_size
      end

      private

      # As definited in draft 06 7.2.2, some failures require that the server
      # abort the websocket connection rather than close cleanly
      def abort
        close_connection
      end

      def close_websocket_private(code, body = nil)
        if @handler
          debug [:closing, code]
          @handler.close_websocket(code, body)
        else
          # The handshake hasn't completed - should be safe to terminate
          abort
        end
      end
    end
  end
end
