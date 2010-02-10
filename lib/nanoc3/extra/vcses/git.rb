# encoding: utf-8

module Nanoc3::Extra::VCSes

  # @see Nanoc3::Extra::VCS
  class Git < Nanoc3::Extra::VCS

    # @see Nanoc3::Extra::VCS#add
    def add(filename)
      system('git', 'add', filename)
    end

    # @see Nanoc3::Extra::VCS#remove
    def remove(filename)
      system('git', 'rm', filename)
    end

    # @see Nanoc3::Extra::VCS#move
    def move(src, dst)
      system('git', 'mv', src, dst)
    end

  end

end
