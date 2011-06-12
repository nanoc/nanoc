module Nanoc3::CLI

  # Nanoc3::CLI::Command is an abstract superclass for all commands.
  class Command < ::Cri::Command

    # @return [Nanoc3::CLI::Command] The shared instance for this object
    def self.shared_instance
      @shared_instance ||= self.new
    end

    # Called when a new command class is created.
    #
    # @param [Class] The command class
    #
    # @return [void]
    def self.inherited(command_subclass)
      Nanoc3::CLI::Base.shared_base.add_command(
        command_subclass.shared_instance)
    end

  end

end
