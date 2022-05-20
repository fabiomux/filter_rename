# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'filter_rename/version'

Gem::Specification.new do |spec|
  spec.name          = "filter_rename"
  spec.version       = FilterRename::VERSION
  spec.authors       = ["Fabio Mucciante"]
  spec.email         = ["fabio.mucciante@gmail.com"]

  spec.summary       = %q{File renaming tool which make use of a chain of actions called filters.}
  spec.description   = %q{FilterRename is a bulk renaming tool, based on the concept of filters as small operations to perform over sections of the full filename logically represented in targets.}
  spec.homepage      = "https://github.com/fabiomux/filter_rename"
  spec.license       = "GPL-3.0"

  spec.metadata      = {
    "bug_tracker_uri"   => "https://github.com/fabiomux/filter_rename/issues",
    "changelog_uri"     => "https://freeaptitude.altervista.org/projects/filter-rename.htm#changelog",
    "documentation_uri" => "https://www.rubydoc.info/gems/filter_rename/#{spec.version}",
    "homepage_uri"      => "https://freeaptitude.altervista.org/projects/filter-rename.html",
    #"mailing_list_uri"  => "",
    "source_code_uri"   => "https://github.com/fabiomux/filter_rename",
    "wiki_uri"          => "https://github.com/fabiomux/filter_rename/wiki"
  }

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"

  spec.add_runtime_dependency "mp3info"
  spec.add_runtime_dependency "mimemagic"
  spec.add_runtime_dependency "differ"
  spec.add_runtime_dependency "exiv2"
  spec.add_runtime_dependency "fastimage"
  spec.add_runtime_dependency "pdf-reader"
end
