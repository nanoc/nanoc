begin
  require 'rubocop/rake_task'

  RuboCop::RakeTask.new(:rubocop) do |task|
    task.patterns = ['lib/**/*.rb']
  end
rescue LoadError
  warn "Could not load RuboCop. RuboCop rake tasks will be unavailable."
end
