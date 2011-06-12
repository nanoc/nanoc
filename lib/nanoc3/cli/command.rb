module Nanoc3::CLI

  # Nanoc3::CLI::Command is an abstract superclass for all commands.
  class Command < ::Cri::Command

    # TODO document
    def self.shared_instance
      @shared_instance ||= self.new
    end

    # TODO document
    def added_to_base(base)
    end

    # TODO document
    def self.inherited(command_subclass)
      shared_base = Nanoc3::CLI::Base.shared_base
      shared_instance = command_subclass.shared_instance
      shared_base.add_command(shared_instance)
      shared_instance.added_to_base(shared_base)
    end

  end

end
