# encoding: utf-8

module Nanoc3::Extra::VCSes

  # @see Nanoc3::Extra::VCS
  class Subversion < Nanoc3::Extra::VCS

    # @see Nanoc3::Extra::VCS#add
    def add(filename)
      system('svn', 'add', filename)
    end

    # @see Nanoc3::Extra::VCS#remove
    def remove(filename)
      system('svn', 'rm', filename)
    end

    # @see Nanoc3::Extra::VCS#move
    def move(src, dst)
      system('svn', 'mv', src, dst)
    end

  end

end
