# frozen_string_literal: true

require_relative "lib/jekyll/sticky_toc/version"

Gem::Specification.new do |spec|
  spec.name = "jekyll-sticky-toc"
  spec.version = Jekyll::StickyToc::VERSION
  spec.authors = ["devl79"]
  spec.email = [""]

  spec.summary = "Jekyll plugin for an automatic sticky table of contents."
  spec.homepage = "https://github.com/developerlee79/jekyll-sticky-toc"
  spec.required_ruby_version = ">= 2.7.0"
  spec.licenses = ["MIT"]

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  spec.files = Dir["lib/**/*", "assets/**/*"] + %w[README.md LICENSE]
  spec.require_paths = ["lib"]

  spec.add_dependency "jekyll", "~> 4.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rubocop", "~> 1.0"
end
