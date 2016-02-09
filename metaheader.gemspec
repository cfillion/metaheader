# coding: utf-8
lib = File.expand_path '../lib', __FILE__
$LOAD_PATH.unshift lib unless $LOAD_PATH.include? lib

require 'metaheader/version'

Gem::Specification.new do |spec|
  spec.name          = "metaheader"
  spec.version       = MetaHeader::VERSION
  spec.authors       = ["cfillion"]
  spec.email         = ["metaheader@cfillion.tk"]
  spec.summary       = %q{Parser for metadata headers in plain-text files}
  spec.homepage      = "https://github.com/cfillion/metaheader"
  spec.license       = "LGPL-3.0+"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency 'bundler', '~> 1.10'
  spec.add_development_dependency 'coveralls', '~> 0.8'
  spec.add_development_dependency 'minitest', '~> 5.8'
  spec.add_development_dependency 'rake'
end
