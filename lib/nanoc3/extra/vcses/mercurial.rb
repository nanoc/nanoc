# encoding: utf-8

module Nanoc3::Extra::VCSes

  # @see Nanoc3::Extra::VCS
  class Mercurial < Nanoc3::Extra::VCS

    # @see Nanoc3::Extra::VCS#add
    def add(filename)
      system('hg', 'add', filename)
    end

    # @see Nanoc3::Extra::VCS#remove
    def remove(filename)
      system('hg', 'rm', filename)
    end

    # @see Nanoc3::Extra::VCS#move
    def move(src, dst)
      system('hg', 'mv', src, dst)
    end

  end

end
