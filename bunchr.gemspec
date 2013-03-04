# -*- encoding: utf-8 -*-
$:.push('lib')
require "bunchr/version"

Gem::Specification.new do |s|
  s.name     = "bunchr"
  s.version  = Bunchr::VERSION.dup
  s.date     = "2012-04-17"
  s.summary  = "A DSL for bundling complex software projects into 'omnibus'-style packages."
  s.email    = "joeym@joeym.net"
  s.homepage = "https://github.com/joemiller/bunchr"
  s.authors  = ['Joe Miller']
  
  s.description = <<-EOF
A DSL for building complex software projects and packaging them (RPM, DEB, etc).
Originally developed to create "omnibus" style packages that include an entire
ruby stack along with one or more gems, but useful for general compilation and
packaging as well.
EOF

  s.files = FileList.new('README.md', 'example_recipes/**/*', 'lib/**/*')
  s.require_paths = ["lib"]
  
  ## Make sure you can build the gem on older versions of RubyGems too:
  s.rubygems_version = "1.3.6"
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.specification_version = 3 if s.respond_to? :specification_version
  
  s.add_dependency("rake", ">= 0.8.7")
  s.add_dependency("ohai")
  s.add_dependency("systemu")
  s.add_dependency("fpm", "= 0.4.26")
end
