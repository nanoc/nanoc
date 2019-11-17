# frozen_string_literal: true

require 'nanoc-core'
require 'nanoc-cli'

module Nanoc
  module Deploying
  end
end

require 'nanoc/deploying/version'
require 'nanoc/deploying/deployer'
require 'nanoc/deploying/deployers'

Nanoc::CLI.after_setup do
  root = File.dirname(__FILE__)
  deploying_command_path = File.join(root, 'deploying', 'commands', 'deploy.rb')
  Nanoc::CLI.add_command(Cri::Command.load_file(deploying_command_path, infer_name: true))

  Nanoc::CLI::Commands::ShowPlugins.add_plugin_class(Nanoc::Deploying::Deployer, 'Deployers')
end
