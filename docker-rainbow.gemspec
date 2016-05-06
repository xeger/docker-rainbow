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
  spec.description   = %q{Generates terse, meaningful, unique names for your Docker containers.}
  spec.homepage      = "https://github.com/xeger/docker-rainbow"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
end
