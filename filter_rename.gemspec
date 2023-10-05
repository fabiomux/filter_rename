# frozen_string_literal: true

require_relative "lib/filter_rename/version"

Gem::Specification.new do |spec|
  spec.name          = "filter_rename"
  spec.version       = FilterRename::VERSION
  spec.authors       = ["Fabio Mucciante"]
  spec.email         = ["fabio.mucciante@gmail.com"]

  spec.summary       = "File renaming tool which make use of a chain of actions called filters."
  spec.description   = "FilterRename is a bulk renaming tool, based on the concept of filters as small operations " \
                       "to perform over sections of the full filename logically represented in targets."
  spec.homepage      = "https://github.com/fabiomux/filter_rename"
  spec.license       = "GPL-3.0"
  spec.required_ruby_version = ">= 2.5.0"

  spec.metadata = {
    "bug_tracker_uri" => "https://github.com/fabiomux/filter_rename/issues",
    "homepage_uri" => "https://freeaptitude.altervista.org/projects/filter-rename.html",
    "source_code_uri" => "https://github.com/fabiomux/filter_rename",
    "changelog_uri" => "https://freeaptitude.altervista.org/projects/filter-rename.htm#changelog",
    "wiki_uri" => "https://github.com/fabiomux/filter_rename/wiki",
    "rubygems_mfa_required" => "true"
  }

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"

  spec.add_runtime_dependency "differ"
  spec.add_runtime_dependency "exiv2"
  spec.add_runtime_dependency "fastimage"
  spec.add_runtime_dependency "mimemagic"
  spec.add_runtime_dependency "mp3info"
  spec.add_runtime_dependency "pdf-reader"
  spec.add_runtime_dependency "taglib-ruby"
end
