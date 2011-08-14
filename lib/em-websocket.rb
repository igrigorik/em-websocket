$:.unshift(File.dirname(__FILE__) + '/../lib')

require "eventmachine"

%w[
  debugger websocket connection
  handshake10 handshake75 handshake76 handshake04
  framing10 framing76 framing03 framing04 framing05 framing07
  close10 close75 close03 close05 close06
  masking04
  message_processor_03 message_processor_06
  handler_factory handler handler10 handler75 handler76 handler03 handler05 handler06 handler07 handler08
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

unless ''.respond_to?(:force_encoding)
  class String
    def force_encoding(*); self; end
  end
end
