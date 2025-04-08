# frozen_string_literal: true

require_relative "lib/data_style_sanitizer/version"

Gem::Specification.new do |spec|
  spec.name = "data_style_sanitizer"
  spec.version = DataStyleSanitizer::VERSION
  spec.authors = ["tedaford"]
  spec.email = ["daturafarms@gmail.com"]

  spec.summary = "Converts data-style attributes into CSP-compliant nonced style blocks"
  spec.description = "This is a gem that converts data-style attributes into CSP-compliant nonced style blocks. It is designed to work with Rails applications and provides a simple interface for sanitizing HTML content."
  spec.homepage = "https://github.com/tedaford/data_style_sanitizer"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/tedaford/data_style_sanitizer"
  spec.metadata["changelog_uri"] = "https://github.com/tedaford/data_style_sanitizer/blob/master/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # Use `git ls-files` to include all tracked files.
  spec.files = Dir["lib/**/*.rb"] + %w[
    README.md
    LICENSE.txt
    CHANGELOG.md
  ]

  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Dependencies
  spec.add_dependency "nokogiri"
  spec.add_dependency "securerandom"
  spec.add_dependency "rails", "~> 7.1.0"
end
