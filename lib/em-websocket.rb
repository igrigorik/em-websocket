$:.unshift(File.dirname(__FILE__) + '/../lib')

#require "rubygems"
require "eventmachine"

%w[
  debugger websocket connection
  handshake75 handshake76
  framing76
  handler_factory handler handler75 handler76
].each do |file|
  require "em-websocket/#{file}"
end
