begin
  require 'rubocop/rake_task'

  Rubocop::RakeTask.new(:rubocop) do |task|
    task.patterns = ['lib/**/*.rb']
  end
rescue LoadError
  warn "Could not load Rubocop. Rubocop rake tasks will be unavailable."
end
