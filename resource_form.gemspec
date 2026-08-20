require_relative "lib/resource_form/version"

Gem::Specification.new do |spec|
  spec.name        = "resource_form"
  spec.version     = ResourceForm::VERSION
  spec.authors     = ["mira"]
  spec.summary     = "Auto-detecting Rails form builder with partial templates per CSS framework."
  spec.license     = "MIT"
  spec.required_ruby_version = ">= 3.2"
  spec.files       = Dir["{app,lib}/**/*", "README.md"]

  spec.add_dependency "rails", ">= 7.0"
  spec.add_dependency "resource_core"
end
