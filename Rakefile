require 'bundler'
Bundler::GemHelper.install_tasks

require 'spec/rake/spectask'

Spec::Rake::SpecTask.new do |t|
  t.ruby_opts = ['-rtest/unit']
  t.spec_files = FileList['spec/**/*_spec.rb']
end
