require 'rake/rdoctask'

namespace :doc do

  Rake::RDocTask.new do |task|
    task.rdoc_files.include(GemSpec.extra_rdoc_files + [ 'lib' ])
    task.rdoc_dir = 'rdoc'
    task.options = GemSpec.rdoc_options
  end

end

desc 'Alias for doc:rdoc'
task :doc => [ :'doc:rdoc' ]
