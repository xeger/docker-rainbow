# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'docker/rainbow/version'

Gem::Specification.new do |spec|
  spec.name          = "docker-rainbow"
  spec.version       = Docker::Rainbow::VERSION
  spec.authors       = ["Tony Spataro"]
  spec.email         = ["tony@rightscale.com"]

  spec.summary       = %q{An Ops-friendly container naming scheme for Docker.}
  spec.description   = %q{Chooses terse, meaningful, unique names for containers based on base image, existing containers, and other factors.}
  spec.homepage      = "https://github.com/xeger/docker-rainbow"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # We use ActiveSupport core_ext, which works pretty much the same way from
  # 2.0.0 onward...
  spec.add_dependency "activesupport", "> 2.0"

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
end
