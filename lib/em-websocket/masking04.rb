module EventMachine
  module WebSocket
    class MaskedString < String
      # Read a 4 bit XOR mask - further requested bytes will be unmasked
      def read_mask
        if respond_to?(:encoding) && encoding.name != "ASCII-8BIT"
          raise "MaskedString only operates on BINARY strings"
        end
        raise "Too short" if bytesize < 4 # TODO - change
        @masking_key = String.new(self[0..3])
      end

      # Removes the mask, behaves like a normal string again
      def unset_mask
        @masking_key = nil
      end

      def slice_mask
        slice!(0, 4)
      end

      def getbyte(index)
        if @masking_key
          masked_char = super
          masked_char ? masked_char ^ @masking_key.getbyte(index % 4) : nil
        else
          super
        end
      end

      def getbytes(start_index, count)
        data = ''.force_encoding('ASCII-8BIT')
        count.times do |i|
          data << getbyte(start_index + i)
        end
        data
      end
    end
  end
end
