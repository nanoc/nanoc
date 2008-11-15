require 'rake/rdoctask'

Rake::RDocTask.new do |task|
  task.rdoc_files.include(GemSpec.extra_rdoc_files + [ 'lib' ])
  task.rdoc_dir = 'rdoc'
  task.options = GemSpec.rdoc_options
end
