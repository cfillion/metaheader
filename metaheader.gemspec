# coding: utf-8
lib = File.expand_path '../lib', __FILE__
$LOAD_PATH.unshift lib unless $LOAD_PATH.include? lib

require 'metaheader/version'

Gem::Specification.new do |spec|
  spec.name          = "metaheader"
  spec.version       = MetaHeader::VERSION
  spec.authors       = ["cfillion"]
  spec.email         = ["metaheader@cfillion.ca"]
  spec.summary       = %q{Parser for metadata headers in plain-text files}
  spec.homepage      = "https://github.com/cfillion/metaheader"
  spec.license       = "LGPL-3.0+"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '>= 2.3'

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'minitest', '~> 5.10'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'simplecov', '~> 0.13'
end
