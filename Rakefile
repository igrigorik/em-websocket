require 'rake'
require 'spec/rake/spectask'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "em-websocket"
    gemspec.summary = "EventMachine based WebSocket server"
    gemspec.description = gemspec.summary
    gemspec.email = "ilya@igvita.com"
    gemspec.homepage = "http://github.com/igrigorik/em-websocket"
    gemspec.authors = ["Ilya Grigorik"]
    gemspec.add_dependency("eventmachine", ">= 0.12.9")
    gemspec.add_dependency("addressable", '>= 2.1.1')
    gemspec.add_development_dependency('em-http-request', '>= 0.2.6')
    gemspec.rubyforge_project = "em-websocket"
  end

  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install jeweler -s http://gemcutter.org"
end

task :default => :spec

Spec::Rake::SpecTask.new do |t|
  t.ruby_opts = ['-rtest/unit']
  t.spec_files = FileList['spec/**/*_spec.rb']
end


