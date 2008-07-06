module Nanoc

  # TODO document
  class VCS < Nanoc::Plugin

    # TODO document
    def self.named(identifier)
      # Initialize list of VCSes if necessary
      @vcses ||= {}

      # Find VCS
      @vcses[identifier] ||= Nanoc::PluginManager.instance.find(
        Nanoc::VCS, :identifiers, identifier
      )
    end

    # TODO document
    def add(filename)
      not_implemented('add')
    end

    # TODO document
    def remove(filename)
      not_implemented('remove')
    end

    # TODO document
    def move(src, dst)
      not_implemented('move')
    end

  private

    def not_implemented(name)
      raise NotImplementedError.new(
        "#{self.class} does not override ##{name}, which is required for " +
        "this data source to be used."
      )
    end

  end

end
