require 'nanoc3/package'

require 'rubygems/package_task'

namespace :gem do

  package_task = Gem::PackageTask.new(Nanoc3::Package.instance.gem_spec) { |pkg| }

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
