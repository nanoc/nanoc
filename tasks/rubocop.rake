# encoding: utf-8

begin
  require 'rubocop/rake_task'

  RuboCop::RakeTask.new(:rubocop) do |task|
    task.options  = %w( --display-cop-names --format simple )
    task.patterns = ['lib/**/*.rb']
  end
rescue LoadError
  warn 'Could not load RuboCop. RuboCop rake tasks will be unavailable.'
end
