require 'minitest/unit'

test = namespace :test do

  # test:rcov
  desc 'Generate code coverage stats'
  task :rcov do
    sh %{rcov test/**/test_*.rb -I test -x /Library}
  end

  # test:all
  desc 'Run all tests'
  task :all do
    ENV['QUIET'] ||= 'true'

    $LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + '/..'))

    MiniTest::Unit.autorun

    test_files = Dir['test/**/*_spec.rb'] + Dir['test/**/test_*.rb']
    test_files.each { |f| require f }
  end

  # test:...
  %w( base cli data_sources extra filters helpers routers tasks ).each do |dir|
    desc "Run all #{dir} tests"
    task dir.to_sym do |task|
      ENV['QUIET'] ||= 'true'

      $LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + '/..'))

      MiniTest::Unit.autorun

      test_files = Dir["test/#{dir}/**/*_spec.rb"] + Dir["test/#{dir}/**/test_*.rb"]
      test_files.each { |f| require f }
    end
  end

end

desc 'Alias for test:all'
task :test => [ :'test:all' ]
