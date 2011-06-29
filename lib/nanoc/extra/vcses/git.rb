# encoding: utf-8

module Nanoc::Extra::VCSes

  # @see Nanoc::Extra::VCS
  class Git < Nanoc::Extra::VCS

    # @see Nanoc::Extra::VCS#add
    def add(filename)
      system('git', 'add', filename)
    end

    # @see Nanoc::Extra::VCS#remove
    def remove(filename)
      system('git', 'rm', filename)
    end

    # @see Nanoc::Extra::VCS#move
    def move(src, dst)
      system('git', 'mv', src, dst)
    end

  end

end
