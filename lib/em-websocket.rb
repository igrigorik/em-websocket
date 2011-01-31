$:.unshift(File.dirname(__FILE__) + '/../lib')

require "eventmachine"

%w[
  debugger websocket connection
  handshake75 handshake76
  framing76 framing03
  handler_factory handler handler75 handler76 handler03
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
