module EventMachine
  module WebSocket
    module Masking04
      attr_accessor :masking_key

      def unmask(data, position)
        unmasked_data = ""
        data.size.times do |i|
          unmasked_data << (data.getbyte(i) ^ masking_key.getbyte(position % 4))
          position += 1
        end
        unmasked_data
      end
    end
  end
end
