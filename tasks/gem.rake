# encoding: utf-8

require 'nanoc3/package'

begin
  require 'rubygems/package_task'
  GemPackageTask = ::Gem::PackageTask
rescue LoadError
  warn 'could not load “rubygems/package_task”; consider upgrading rubygems'
  GemPackageTask = ::Rake::GemPackageTask
end

namespace :gem do

  package_task = GemPackageTask.new(Nanoc3::Package.instance.gem_spec) { |pkg| }

  desc 'Install the gem'
  task :install => [ :package ] do
    sh %{gem install pkg/#{package_task.name}-#{Nanoc3::VERSION}}
  end

  desc 'Uninstall the gem'
  task :uninstall do
    sh %{gem uninstall #{package_task.name}}
  end

end

desc 'Alias for gem:package'
task :gem => [ :'gem:package' ]
