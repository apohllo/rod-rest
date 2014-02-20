$:.unshift "lib"
require 'rod/rest/constants'

Gem::Specification.new do |s|
  s.name = "rod-rest"
  s.version = Rod::Rest::VERSION
  s.date = "#{Time.now.strftime("%Y-%m-%d")}"
  s.required_ruby_version = '= 1.9.2'
  s.platform    = Gem::Platform::RUBY
  s.authors = ['Aleksander Pohl']
  s.email   = ["apohllo@o2.pl"]
  s.homepage    = "http://github.com/apohllo/rod-rest"
  s.summary = "REST API for ROD"
  s.description = "REST API for Ruby Object Database allows for talking to the DB via HTTP."

  s.rubyforge_project = "rod-rest"
  #s.rdoc_options = ["--main", "README.rdoc"]

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_path = "lib"

  s.add_dependency("sinatra")
  s.add_dependency("rod")
  s.add_dependency("faraday")

  s.add_development_dependency("rack-test")
  s.add_development_dependency("rspec")
  s.add_development_dependency("rr")
end

