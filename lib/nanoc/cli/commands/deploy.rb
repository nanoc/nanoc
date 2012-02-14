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
flag   :l, :list,      'list available locations to deploy to'
option :n, :'dry-run', 'show what would be deployed'

module Nanoc::CLI::Commands

  class Deploy < ::Nanoc::CLI::CommandRunner

    def run
      require_site

      # Get config
      deploy_configs = site.config.fetch(:deploy) do
        $stderr.puts "The site configuration has no deploy configuration."
        exit 1
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
      target = options.fetch(:target) do
        $stderr.puts "The deploy command requires a --target option."
        exit 1
      end
      target = target.to_sym
      config = deploy_configs.fetch(target) do
        $stderr.puts "The site configuration has no deploy configuration for #{target}."
        exit 1
      end

      # Get deployer
      names = Nanoc::Extra::Deployer.all.keys
      name = config.fetch(:kind) do
        $stderr.puts "The specified deploy target does not have a kind."
        $stderr.puts "(expected one of #{names.join(', ')})"
        exit 1
      end
      deployer_class = Nanoc::Extra::Deployer.named(name) do
        $stderr.puts "The specified deploy target has an unrecognised kind (#{kind})."
        $stderr.puts "(expected one of #{names.join(', ')})"
        exit 1
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
