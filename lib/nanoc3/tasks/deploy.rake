# encoding: utf-8

namespace :deploy do

  desc 'Upload the compiled site using rsync'
  task :rsync do
    deploy_task = Nanoc3::Tasks::Deploy::Rsync.new
    deploy_task.run :dry_run => !!ENV['DRY_RUN']
  end

end
