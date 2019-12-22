# frozen_string_literal: true

module Nanoc
  module Deploying
    module CommandRunners
      class Deploy < ::Nanoc::CLI::CommandRunner
        def run
          @site = load_site
          Nanoc::Core::Compiler.new_for(@site).run_until_preprocessed

          if options[:'list-deployers']
            list_deployers
          elsif options[:list]
            list_deploy_configs
          else
            deploy
          end
        end

        private

        def list_deployers
          deployers      = Nanoc::Deploying::Deployer.all
          deployer_names = deployers.map(&:identifier).sort
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
            deploy_configs.each_key do |name|
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
            raise Nanoc::Core::TrivialError, 'The site has no deployment configurations.'
          end

          if arguments.length > 1
            raise Nanoc::Core::TrivialError, "usage: #{command.usage}"
          end

          target_from_arguments = arguments[0]
          target_from_options = options.fetch(:target, nil)
          if target_from_arguments && target_from_options
            raise Nanoc::Core::TrivialError, 'Only one deployment target can be specified on the command line.'
          end

          target = target_from_arguments || target_from_options || :default
          deploy_configs.fetch(target.to_sym) do
            raise Nanoc::Core::TrivialError, "The site has no deployment configuration named `#{target}`."
          end
        end

        def deployer_for(config)
          deployer_class_for_config(config).new(
            @site.config.output_dir,
            config,
            dry_run: options[:'dry-run'],
          )
        end

        def check
          runner = Nanoc::Checking::Runner.new(@site)
          if runner.any_enabled_checks?
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
          @site.config.fetch(:deploy, {})
        end

        def deployer_class_for_config(config)
          name = config.fetch(:kind) do
            $stderr.puts 'Warning: The specified deploy target does not have a kind attribute. Assuming rsync.'
            'rsync'
          end

          deployer_class = Nanoc::Deploying::Deployer.named(name.to_sym)
          if deployer_class.nil?
            names = Nanoc::Deploying::Deployer.all.map(&:identifier)
            raise Nanoc::Core::TrivialError, "The specified deploy target has an unrecognised kind “#{name}” (expected one of #{names.join(', ')})."
          end
          deployer_class
        end
      end
    end
  end
end
