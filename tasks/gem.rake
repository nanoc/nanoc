require 'rake/gempackagetask'

namespace :gem do

  Rake::GemPackageTask.new(GemSpec) { |task| }

  desc 'Install the gem'
  task :install => [ :gem ] do
    sh %{gem install pkg/#{GemSpec.name}-#{Nanoc::VERSION}}
  end

  desc 'Uninstall the gem'
  task :uninstall do
    sh %{gem uninstall #{GemSpec.name}}
  end

end

desc 'Alias for gem:package'
task :gem => [ :'gem:package' ]
