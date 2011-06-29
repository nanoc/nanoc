# encoding: utf-8

module Nanoc::Extra::VCSes

  # @see Nanoc::Extra::VCS
  class Bazaar < Nanoc::Extra::VCS

    # @see Nanoc::Extra::VCS#add
    def add(filename)
      system('bzr', 'add', filename)
    end

    # @see Nanoc::Extra::VCS#remove
    def remove(filename)
      system('bzr', 'rm', filename)
    end

    # @see Nanoc::Extra::VCS#move
    def move(src, dst)
      system('bzr', 'mv', src, dst)
    end

  end

end
