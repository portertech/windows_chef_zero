# coding: utf-8

Gem::Specification.new do |spec|
  spec.name          = "windows_chef_zero"
  spec.version       = "2.0.0"
  spec.authors       = ["Sean Porter"]
  spec.email         = ["portertech@gmail.com"]
  spec.summary       = "A Test-Kitchen Chef Zero provisioner for Windows"
  spec.description   = "A Test-Kitchen Chef Zero provisioner for Windows"
  spec.homepage      = "https://github.com/portertech/windows_chef_zero"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "test-kitchen", ">= 1.2.1"

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
end
