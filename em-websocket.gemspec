# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "em-websocket/version"

Gem::Specification.new do |s|
  s.name        = "em-websocket"
  s.version     = EventMachine::Websocket::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Ilya Grigorik", "Martyn Loughran"]
  s.email       = ["ilya@igvita.com", "me@mloughran.com"]
  s.homepage    = "http://github.com/igrigorik/em-websocket"
  s.summary     = %q{EventMachine based WebSocket server}
  s.description = %q{EventMachine based WebSocket server}

  s.rubyforge_project = "em-websocket"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency("eventmachine", ">= 0.12.9")
  s.add_dependency("addressable", '>= 2.1.1')
  s.add_development_dependency('em-spec', '~> 0.2.6')
  s.add_development_dependency("eventmachine", "~> 0.12.10")
  s.add_development_dependency('em-http-request', '~> 0.2.6')
  s.add_development_dependency('rspec', "~> 2.8.0")
  s.add_development_dependency('rake')
end
