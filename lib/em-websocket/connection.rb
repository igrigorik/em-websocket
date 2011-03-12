require 'addressable/uri'

module EventMachine
  module WebSocket
    class Connection < EventMachine::Connection
      include Debugger

      # define WebSocket callbacks
      def onopen(&blk);     @onopen = blk;    end
      def onclose(&blk);    @onclose = blk;   end
      def onerror(&blk);    @onerror = blk;   end
      def onmessage(&blk);  @onmessage = blk; end

      def trigger_on_message(msg)
        @onmessage.call(msg) if @onmessage
      end
      def trigger_on_open
        @onopen.call if @onopen
      end
      def trigger_on_close
        @onclose.call if @onclose
      end

      def initialize(options)
        @options = options
        @debug = options[:debug] || false
        @secure = options[:secure] || false
        @tls_options = options[:tls_options] || {}
        @data = ''

        debug [:initialize]
      end

      # Use this method to close the websocket connection cleanly
      # This sends a close frame and waits for acknowlegement before closing
      # the connection
      def close_websocket(code = nil, body = nil)
        if @handler
          @handler.close_websocket(code, body)
        else
          # The handshake hasn't completed - should be safe to terminate
          close_connection
        end
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
      end

      def unbind
        debug [:unbind, :connection]

        @handler.unbind if @handler
      end

      def dispatch(data)
        if data.match(/\A<policy-file-request\s*\/>/)
          send_flash_cross_domain_file
          return false
        else
          debug [:inbound_headers, data]
          begin
            @data << data
            @handler = HandlerFactory.build(self, @data, @secure, @debug)
            unless @handler
              # The whole header has not been received yet.
              return false
            end
            @data = nil
            @handler.run
            return true
          rescue => e
            debug [:error, e]
            process_bad_request(e)
            return false
          end
        end
      end

      def process_bad_request(reason)
        @onerror.call(reason) if @onerror
        send_data "HTTP/1.1 400 Bad request\r\n\r\n"
        close_connection_after_writing
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

      def send(data)
        if @handler
          @handler.send_text_frame(data)
        else
          raise WebSocketError, "Cannot send data before onopen callback"
        end
      end

      def close_with_error(message)
        @onerror.call(message) if @onerror
        close_connection_after_writing
      end

      def request
        @handler ? @handler.request : {}
      end

      def state
        @handler ? @handler.state : :handshake
      end
    end
  end
end
