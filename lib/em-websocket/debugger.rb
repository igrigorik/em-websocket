module EventMachine
  module WebSocket
    module Debugger

      private

      def debug(*data)
        data.flatten!
        if @debug || data.first == :error
          require 'pp'
          pp data
          data.each do |datum|
            puts datum.backtrace if datum.respond_to?(:backtrace)
          end
          puts
        end
      end

    end
  end
end
