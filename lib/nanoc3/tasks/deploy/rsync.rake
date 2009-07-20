# encoding: utf-8

namespace :deploy do

  desc 'Upload the compiled site using rsync'
  task :rsync do
    deployer = Nanoc3::Extra::Deployers::Rsync.new
    deployer.run :dry_run => !!ENV['DRY_RUN']
  end

end
