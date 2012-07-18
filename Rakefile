require 'rubygems'
require 'janda/tasks'

namespace :build do
  task :local do
    raise unless system('spec -c --format nested spec ')
  end
end

task :default => ['build:local']