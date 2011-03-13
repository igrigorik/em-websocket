module EventMachine
  module WebSocket
    module Debugger

      private

      def debug(*data)
        data.flatten!
        if @debug || data.first == :error
          require 'pp'
          pp data
          puts
        end
      end

    end
  end
end
