task :default => ["test:spec", "test:int"]

namespace :test do
  desc "Specs"
  task :spec do
    sh "rspec test/spec/api.rb"
    sh "rspec test/spec/client.rb"
    sh "rspec test/spec/proxy.rb"
    sh "rspec test/spec/collection_proxy.rb"
    sh "rspec test/spec/json_serializer.rb"
    sh "rspec test/spec/metadata.rb"
    sh "rspec test/spec/resource_metadata.rb"
    sh "rspec test/spec/property_metadata.rb"
    sh "rspec test/spec/proxy_factory.rb"
  end

  desc "Integration tests" 
  task :int do
    sh "rspec test/int/end_to_end.rb"
  end
end
