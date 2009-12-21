$:.unshift(File.dirname(__FILE__) + '/../lib')

require "rubygems"
require "eventmachine"

%w[ websocket connection ].each do |file|
  require "em-websocket/#{file}"
end
