# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ubb/version'

Gem::Specification.new do |spec|
  spec.name          = "ubb"
  spec.version       = Ubb::VERSION
  spec.authors       = ["fum1h1ro"]
  spec.email         = ["fumihiro@gmail.com"]
  spec.summary       = %q{Unity Batch Build Helper}
  spec.description   = %q{Helping batch build from Unity Editor}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib", "bin"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
end
