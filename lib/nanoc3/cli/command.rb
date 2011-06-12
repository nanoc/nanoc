module Nanoc3::CLI

  # Nanoc3::CLI::Command is an abstract superclass for all commands.
  class Command < ::Cri::Command

    # TODO document
    def self.shared_instance
      @shared_instance ||= self.new
    end

    # TODO document
    def self.inherited(command_subclass)
      Nanoc3::CLI::Base.shared_base.add_command(
        command_subclass.shared_instance)
    end

  end

end
