# encoding: utf-8

namespace :deploy do

  desc 'Upload the compiled site using rsync'
  task :rsync do
    dry_run     = !!ENV['dry_run']
    config_name = ENV['config'] || :default

    deployer = Nanoc3::Extra::Deployers::Rsync.new
    deployer.run(:config_name => config_name, :dry_run => dry_run)
  end

end
