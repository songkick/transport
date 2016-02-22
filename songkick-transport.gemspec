Gem::Specification.new do |s|
  s.name                  = "songkick-transport"
  s.version               = "1.10.3"
  s.license               = "MIT"
  s.summary               = "HTTP client abstraction for service clients"
  s.description           = "HTTP client abstraction for service clients"
  s.authors               = ["Daniel Lucraft", "James Coglan", "Sabrina Leandro", "Robin Tweedie", "Paul Lawson", "Sabina Bejasa-Dimmock", "Paul Springett"]
  s.email                 = "developers@songkick.com"
  s.homepage              = "http://github.com/songkick/transport"
  s.required_ruby_version = '>= 1.8.7'

  s.extra_rdoc_files  = %w[README.rdoc]
  s.rdoc_options      = %w[--main README.rdoc]
  s.require_paths     = %w[lib]

  s.files = %w[README.rdoc] + Dir.glob("{examples,lib,spec}/**/*.rb") + Dir.glob("{examples,lib,spec}/**/*.erb")

  s.add_dependency "multipart-post", ">= 1.1.0"
  s.add_dependency "yajl-ruby", ">= 1.1.0"

  s.add_development_dependency "activesupport", ">= 3.0.0"
  s.add_development_dependency "curb", ">= 0.3.0"
  s.add_development_dependency "httparty", ">= 0.8.0"
  s.add_development_dependency "rack-test", ">= 0.4.0"

  s.add_development_dependency "rake"
  s.add_development_dependency "rspec"
  s.add_development_dependency "sinatra"
  s.add_development_dependency "thin"
end
