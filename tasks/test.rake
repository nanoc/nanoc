require 'rake/testtask'

task :rcov do
  sh %{rcov test/**/test_*.rb -I test -x /Library}
end

Rake::TestTask.new(:test) do |task|
  ENV['QUIET'] = 'true'

  task.libs       = [ 'lib', 'test' ]
  task.test_files = Dir['test/**/*_spec.rb'] + Dir['test/**/test_*.rb']
end

task :default => [ :test ]
