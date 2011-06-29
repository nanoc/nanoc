# encoding: utf-8

module Nanoc::Extra::VCSes

  # @see Nanoc::Extra::VCS
  class Subversion < Nanoc::Extra::VCS

    # @see Nanoc::Extra::VCS#add
    def add(filename)
      system('svn', 'add', filename)
    end

    # @see Nanoc::Extra::VCS#remove
    def remove(filename)
      system('svn', 'rm', filename)
    end

    # @see Nanoc::Extra::VCS#move
    def move(src, dst)
      system('svn', 'mv', src, dst)
    end

  end

end
