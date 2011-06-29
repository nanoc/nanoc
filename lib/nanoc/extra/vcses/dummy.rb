# encoding: utf-8

module Nanoc::Extra::VCSes

  # @see Nanoc::Extra::VCS
  class Dummy < Nanoc::Extra::VCS

    # @see Nanoc::Extra::VCS#add
    def add(filename)
    end

    # @see Nanoc::Extra::VCS#remove
    def remove(filename)
      FileUtils.rm_rf(filename)
    end

    # @see Nanoc::Extra::VCS#move
    def move(src, dst)
      FileUtils.move(src, dst)
    end

  end

end
