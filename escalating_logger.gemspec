require_relative 'lib/escalating_logger/version'

Gem::Specification.new do |spec|
  spec.name          = "escalating_logger"
  spec.version       = EscalatingLogger::VERSION
  spec.summary       = "Ruby Logger subclass that automatically increases/decreases verbosity"
  spec.description = <<-DOC
      A transparent subclass of Ruby's Logger that automatically increases log verbosity
      as the number of ERRORs logged exceeds a given rate threshold. The intent is to get
      more log detail when things are going wrong, and less log noise when everything is
      going right.
    DOC
  spec.authors       = ["Alex Glover"]
  spec.email         = ["alexdglover@gmail.com"]
  spec.homepage      = "https://github.com/alexdglover/escalating_logger"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/tree/main/CHANGELOG.md"

  spec.files       = Dir['lib/**/*.rb']
  spec.required_ruby_version = '>= 2.5.0'
  spec.add_dependency 'bozos_buckets', '~> 0.0.w'
  spec.add_development_dependency 'rake', '~> 12.0'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'yard'
end
