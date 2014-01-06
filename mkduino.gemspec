# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'mkduino/version'

Gem::Specification.new do |spec|
  spec.name          = "mkduino"
  spec.version       = Mkduino::VERSION
  spec.authors       = ["David H. Wilkins"]
  spec.email         = ["dwilkins@conecuh.com"]
  spec.description   = %q{Create a GNU Automake project for an Arduino project }
  spec.summary       = %q{Create a GNU Automake project for an Arduino project }
  spec.homepage      = "https://rubygems.org/gems/mkduino"
  spec.license       = "GPLv3"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
