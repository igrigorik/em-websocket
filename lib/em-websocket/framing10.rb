module EventMachine
  module WebSocket
    module Framing10
      MASK_OPCODE = 0b00001111
      MASK_MASK = 0b10000000
      MASK_FIN = 0b10000000
      MASK_LEN = 0b01111111

      OPCODE_CONT = 0x0
      OPCODE_TEXT = 0x1
      OPCODE_BINARY = 0x2
      OPCODE_CLOSE = 0x8
      OPCODE_PING = 0x9
      OPCODE_PONG = 0xA

      def initialize_framing
        @data = ''.force_encoding('binary')
      end
      
      def process_data(newdata)
        debug [:message, @data]

        return  if @data.size < 2

        fo = @data.getbyte(0)
        mlen = @data.getbyte(1)
        fin = (fo & MASK_FIN) != 0
        opcode = fo & MASK_OPCODE
        mask = (mlen & MASK_MASK) != 0
        len = mlen & MASK_LEN

        lenlen = { 126 => 2, 127 => 8}[len] || 0
        masklen = mask ? 4 : 0
        return  if @data.size < 2+lenlen+masklen
        len = @data[2,2].unpack("n").first  if len == 126
        len = @data[2,8].unpack("NN").last  if len == 127  # only support up to 2GB per msg
        return  if @data.size < 2+lenlen+masklen+len

        mask_key = @data[2+lenlen,4]  if mask
        data = @data.slice!(0, 2+lenlen+masklen+len)[2+lenlen+masklen..-1]
        data.size.times {|i| data[i] = (data.getbyte(i) ^ mask_key.getbyte(i%4)).chr }  if mask

        case opcode
        when OPCODE_TEXT then @msg = data.force_encoding('utf-8')
        when OPCODE_BINARY then @msg = data
        when OPCODE_CONT then @msg << data
        when OPCODE_CLOSE
          @state = :closing
          return @connection.close_connection_after_writing
        when OPCODE_PING
          return send_pong
        end
        @connection.trigger_on_message(@msg)  if fin
      end

      def send_pong
        send_frame(OPCODE_PONG, '')
      end
      
      def send_text_frame(data)
        send_frame(OPCODE_TEXT, data)
      end

      def send_binary_frame(data)
        send_frame(OPCODE_BINARY, data)
      end

      def send_close(code, data)
        send_frame(OPCODE_CLOSE, [code, data].pack("na*"))
      end

      def send_frame(opcode, data)
        debug [:sending_frame, data]
        msg = [opcode | MASK_FIN].pack("C")
        len = [data.size].pack("C")  if data.size <= 125
        len = [126, data.size].pack("Cn")  if data.size > 125 and data.size <= 2**16
        len = [127, 0, data.size].pack("CNN")  if data.size > 2**16  # only support msgs up to 2GB
        msg << len << data
        @connection.send_data(msg)
      end
    end
  end
end
