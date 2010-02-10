# encoding: utf-8

module Nanoc3::Extra::VCSes

  # @see Nanoc3::Extra::VCS
  class Bazaar < Nanoc3::Extra::VCS

    # @see Nanoc3::Extra::VCS#add
    def add(filename)
      system('bzr', 'add', filename)
    end

    # @see Nanoc3::Extra::VCS#remove
    def remove(filename)
      system('bzr', 'rm', filename)
    end

    # @see Nanoc3::Extra::VCS#move
    def move(src, dst)
      system('bzr', 'mv', src, dst)
    end

  end

end
