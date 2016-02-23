usage 'deploy [options]'
summary 'deploy the compiled site'
description "
Deploys the compiled site. The compiled site contents in the output directory will be uploaded to the destination, which is specified using the `--target` option.
"

option :t, :target,         'specify the location to deploy to (default: `default`)', argument: :required
flag :C, :'no-check',       'do not run the issue checks marked for deployment'
flag :L, :list,             'list available locations to deploy to'
flag :D, :'list-deployers', 'list available deployers'
option :n, :'dry-run',      'show what would be deployed'

module Nanoc::CLI::Commands
  class Deploy < ::Nanoc::CLI::CommandRunner
    def run
      prepare

      case
      when options[:'list-deployers']
        list_deployers
      when options[:list]
        list_deploy_configs
      else
        deploy
      end
    end

    private

    def prepare
      load_site
      # FIXME: ugly to preprocess here
      @site = site.compiler.action_provider.preprocess(site)
    end

    def list_deployers
      deployers      = Nanoc::Int::PluginRegistry.instance.find_all(Nanoc::Extra::Deployer)
      deployer_names = deployers.keys.sort_by(&:to_s)
      puts 'Available deployers:'
      deployer_names.each do |name|
        puts "  #{name}"
      end
    end

    def list_deploy_configs
      if deploy_configs.empty?
        puts 'No deployment configurations.'
      else
        puts 'Available deployment configurations:'
        deploy_configs.keys.each do |name|
          puts "  #{name}"
        end
      end
    end

    def deploy
      deployer = deployer_for(deploy_config)

      checks_successful = options[:'no-check'] ? true : check
      return unless checks_successful

      deployer.run
    end

    def deploy_config
      if deploy_configs.empty?
        raise Nanoc::Int::Errors::GenericTrivial, 'The site has no deployment configurations.'
      end

      target = options.fetch(:target, :default).to_sym
      deploy_configs.fetch(target) do
        # FIXME: target name is unobvious
        raise Nanoc::Int::Errors::GenericTrivial, "The site has no deployment configuration for #{target}."
      end
    end

    def deployer_for(config)
      deployer_class_for_config(config).new(
        site.config[:output_dir],
        config,
        dry_run: options[:'dry-run'],
      )
    end

    def check
      runner = Nanoc::Extra::Checking::Runner.new(site)
      if runner.dsl_present?
        puts 'Running issue checks…'
        is_success = runner.run_for_deploy
        if is_success
          puts 'No issues found. Deploying!'
        else
          puts 'Issues found, deploy aborted.'
        end
        is_success
      else
        true
      end
    end

    def deploy_configs
      site.config.fetch(:deploy, {})
    end

    def deployer_class_for_config(config)
      names = Nanoc::Extra::Deployer.all.keys
      name = config.fetch(:kind) do
        $stderr.puts 'Warning: The specified deploy target does not have a kind attribute. Assuming rsync.'
        'rsync'
      end

      deployer_class = Nanoc::Extra::Deployer.named(name)
      if deployer_class.nil?
        raise Nanoc::Int::Errors::GenericTrivial, "The specified deploy target has an unrecognised kind “#{name}” (expected one of #{names.join(', ')})."
      end
      deployer_class
    end
  end
end

runner Nanoc::CLI::Commands::Deploy
