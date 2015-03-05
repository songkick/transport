Gem::Specification.new do |s|
  s.name              = "songkick-transport"
  s.version           = "1.5.2"
  s.summary           = "HTTP client abstraction for service clients"
  s.author            = "James Coglan"
  s.email             = "developers@songkick.com"
  s.homepage          = "http://github.com/songkick/transport"

  s.extra_rdoc_files  = %w[README.rdoc]
  s.rdoc_options      = %w[--main README.rdoc]
  s.require_paths     = %w[lib]

  s.files = %w[README.rdoc] + Dir.glob("{examples,lib,spec}/**/*.rb") + Dir.glob("{examples,lib,spec}/**/*.erb")
  
  s.add_dependency "multipart-post", ">= 1.1.0"
  s.add_dependency "yajl-ruby", ">= 1.1.0"
  
  s.add_development_dependency "curb", ">= 0.3.0"
  s.add_development_dependency "httparty", ">= 0.4.0"
  s.add_development_dependency "rack-test", ">= 0.4.0"

  s.add_development_dependency "rspec"
  s.add_development_dependency "sinatra"
  s.add_development_dependency "thin"
end

