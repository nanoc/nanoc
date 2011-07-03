# encoding: utf-8

module Nanoc::CLI::Commands

  class Deploy < ::Nanoc::CLI::Command

    KIND_MAPPING = {
      'rsync' => Nanoc3::Extra::Deployers::Rsync
    }

  end

end

usage       'deploy [options]'
summary     'deploy the compiled site'
description <<-EOS
Deploys the compiled site. The compiled site contents in the output directory will be uploaded to the destination, which is specified using the -t/--target option.

Available deployers: #{Nanoc::CLI::Commands::Deploy::KIND_MAPPING.keys.join(', ')}

EOS

option :t, :target,    'specify the location to deploy to', :argument => :required
option :n, :'dry-run', 'show what would be deployed'

run do |opts, args, cmd|
  Nanoc::CLI::Commands::Deploy.call(opts, args, cmd)
end

module Nanoc::CLI::Commands

  class Deploy < ::Nanoc::CLI::Command

    def run
      require_site

      # Get target
      target = options.fetch(:target) do
        $stderr.puts "The deploy command requires a --target option."
        exit 1
      end
      target = target.to_sym
      deploy_configs = site.config.fetch(:deploy) do
        $stderr.puts "The site configuration has no deploy configuration."
        exit 1
      end
      config = deploy_configs.fetch(target) do
        $stderr.puts "The site configuration has no deploy configuration for #{target}."
        exit 1
      end

      # Get deployer
      kind = config.fetch(:kind) do
        $stderr.puts "The specified deploy target does not have a kind."
        $stderr.puts "(expected one of #{KIND_MAPPING.keys.join(', ')})"
        exit 1
      end
      deployer_class = KIND_MAPPING.fetch(kind) do
        $stderr.puts "The specified deploy target has an unrecognised kind (#{kind})."
        $stderr.puts "(expected one of #{KIND_MAPPING.keys.join(', ')})"
        exit 1
      end

      # Run
      deployer = deployer_class.new
      deployer.run(:config_name => target, :dry_run => options[:'dry-run'])
    end

  end

end
