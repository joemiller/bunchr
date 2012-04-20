$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)

require 'rubygems'
require 'rubygems/package_task'
require 'rake/clean'

require 'bunchr/version'

spec = eval(File.read('bunchr.gemspec'))

Gem::PackageTask.new(spec) do |pkg|
end

desc 'push latest gem to rubygems.org' 
task :push => :package do
  system "gem push pkg/bunchr-#{Bunchr::VERSION}.gem"
end

task :default => :gem
