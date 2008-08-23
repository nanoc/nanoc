require 'rake/gempackagetask'

namespace :gem do

  Rake::GemPackageTask.new(GemSpec) { |task| }

  task :install => [ :gem ] do
    sh %{gem install pkg/#{GemSpec.name}-#{Nanoc::VERSION}}
  end

  task :uninstall do
    sh %{gem uninstall #{GemSpec.name}}
  end

end
