# encoding: utf-8

# Find all
registry       = Nanoc::PluginRegistry.instance
deployer_class = Nanoc::Extra::Deployer
deployers      = registry.find_all(deployer_class)
deployer_names = deployers.keys.sort_by { |k| k.to_s }

usage       'deploy [options]'
summary     'deploy the compiled site'
description <<-EOS
Deploys the compiled site. The compiled site contents in the output directory will be uploaded to the destination, which is specified using the -t/--target option.

Available deployers: #{deployer_names.join(', ')}

EOS

option :t, :target,    'specify the location to deploy to', :argument => :required
flag   :L, :list,      'list available locations to deploy to'
option :n, :'dry-run', 'show what would be deployed'

module Nanoc::CLI::Commands

  class Deploy < ::Nanoc::CLI::CommandRunner

    def run
      require_site

      # Get config
      deploy_configs = site.config.fetch(:deploy) do
        raise Nanoc::Errors::GenericTrivial, "The site configuration has no deploy configuration."
      end

      # List
      if options[:list]
        puts "Available deployment configurations:"
        deploy_configs.keys.each do |name|
          puts "  #{name}"
        end
        return
      end

      # Get target
      target = options.fetch(:target, :default).to_sym
      config = deploy_configs.fetch(target) do
        raise Nanoc::Errors::GenericTrivial, "The site configuration has no deploy configuration for #{target}."
      end

      # Get deployer
      names = Nanoc::Extra::Deployer.all.keys
      name = config.fetch(:kind) do
        $stderr.puts "Warning: The specified deploy target does not have a kind attribute. Assuming rsync."
        'rsync'
      end
      deployer_class = Nanoc::Extra::Deployer.named(name)
      if deployer_class.nil?
        raise Nanoc::Errors::GenericTrivial, "The specified deploy target has an unrecognised kind “#{name}” (expected one of #{names.join(', ')})."
      end

      # Run
      deployer = deployer_class.new(
        site.config[:output_dir],
        config,
        :dry_run => options[:'dry-run'])
      deployer.run
    end

  end

end

runner Nanoc::CLI::Commands::Deploy
