require 'rake/testtask'

test = namespace :test do

  # test:rcov
  desc 'Generate code coverage stats'
  task :rcov do
    sh %{rcov test/**/test_*.rb -I test -x /Library}
  end

  # test:all
  Rake::TestTask.new(:all) do |task|
    ENV['QUIET'] = 'true'

    task.libs       = [ 'lib', 'test' ]
    task.test_files = Dir['test/**/*_spec.rb'] + Dir['test/**/test_*.rb']
  end

  # test:base
  %w( base binary_filters cli data_sources extra filters helpers routers ).each do |dir|
    Rake::TestTask.new(dir) do |task|
      ENV['QUIET'] = 'true'

      task.libs       = [ 'lib', 'test' ]
      task.test_files = Dir["test/#{dir}/**/*_spec.rb"] + Dir["test/#{dir}/**/test_*.rb"]
    end
  end

end

task :test => [ 'test:all' ]
