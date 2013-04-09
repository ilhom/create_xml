# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'create_xml/version'

Gem::Specification.new do |spec|
  spec.name          = "create_xml"
  spec.version       = CreateXml::VERSION
  spec.authors       = ["Ilhom"]
  spec.email         = ["madrahimov.ilhom@gmail.com"]
  spec.description   = %q{Rgenius Create XML}
  spec.summary       = %q{Rgenius Create XML For SYNC}
  spec.homepage      = "http://r-genius.com"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  # spec.add_development_dependency "bundler", "~> 1.3"
  # spec.add_development_dependency "rake"
end
