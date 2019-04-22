# frozen_string_literal: true

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'discard/version'

Gem::Specification.new do |spec|
  spec.name          = "discard"
  spec.version       = Discard::VERSION
  spec.authors       = ["John Hawthorn"]
  spec.email         = ["john.hawthorn@gmail.com"]

  spec.summary       = %q{ActiveRecord soft-deletes done right}
  spec.description   = %q{Allows marking ActiveRecord objects as discarded, and provides scopes for filtering.}
  spec.homepage      = "https://github.com/jhawthorn/discard"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activerecord", ">= 4.2", "< 7"
  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.5.0"
  spec.add_development_dependency "database_cleaner", "~> 1.5"
  spec.add_development_dependency "with_model", "~> 2.0"
  spec.add_development_dependency "sqlite3"
end
