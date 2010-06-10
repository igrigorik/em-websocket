$:.unshift(File.dirname(__FILE__) + '/../lib')

#require "rubygems"
require "eventmachine"

%w[ debugger websocket connection handler_factory handler handler75 handler76 ].each do |file|
  require "em-websocket/#{file}"
end
