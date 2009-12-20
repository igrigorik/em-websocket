$:.unshift(File.dirname(__FILE__) + '/../lib')

require "rubygems"
require "eventmachine"

%w[ websocket ].each do |file|
  require "em-websocket/#{file}"
end
