# encoding: utf-8

module Nanoc::Extra::VCSes

  # @see Nanoc::Extra::VCS
  class Mercurial < Nanoc::Extra::VCS

    # @see Nanoc::Extra::VCS#add
    def add(filename)
      system('hg', 'add', filename)
    end

    # @see Nanoc::Extra::VCS#remove
    def remove(filename)
      system('hg', 'rm', filename)
    end

    # @see Nanoc::Extra::VCS#move
    def move(src, dst)
      system('hg', 'mv', src, dst)
    end

  end

end
