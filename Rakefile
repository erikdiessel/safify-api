require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:rspec)

task :test do
    ENV["RACK_ENV"] = "test"
    Rake::Task["rspec"].execute
end

task :default => :test