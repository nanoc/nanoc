require 'rake/gempackagetask'

Rake::GemPackageTask.new(GemSpec) { |task| }

task :install_gem do
  sh %{rake package}
  sh %{gem install pkg/#{NAME}-#{VERS}}
end

task :uninstall_gem do
  sh %{gem uninstall #{NAME}}
end
