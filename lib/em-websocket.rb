$:.unshift(File.dirname(__FILE__) + '/../lib')

require "eventmachine"

%w[
  debugger websocket connection
  handshake75 handshake76 handshake04
  framing76 framing03 framing04 framing05
  masking04
  message_processor_03 message_processor_06
  handler_factory handler handler75 handler76 handler03 handler05 handler06
].each do |file|
  require "em-websocket/#{file}"
end

unless ''.respond_to?(:getbyte)
  class String
    def getbyte(i)
      self[i]
    end
  end
end
