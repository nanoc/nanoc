namespace :deploy do

  desc 'Upload the compiled site using rsync'
  task :rsync do
    deploy_task = Nanoc::Tasks::Deploy::Rsync.new
    deploy_task.run :dry_run => !!ENV['DRY_RUN']
  end

  desc 'Upload the compiled site using sitecopy'
  task :sitecopy do
    # TODO implement
  end

  desc 'Upload the compiled site using scp'
  task :scp do
    # TODO implement
  end

  desc 'Upload the compiled site using ftp'
  task :ftp do
    # TODO implement
  end

end
