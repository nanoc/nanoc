# encoding: utf-8

module Nanoc3::Extra::VCSes

  # @see Nanoc3::Extra::VCS
  class Dummy < Nanoc3::Extra::VCS

    # @see Nanoc3::Extra::VCS#add
    def add(filename)
    end

    # @see Nanoc3::Extra::VCS#remove
    def remove(filename)
      FileUtils.rm_rf(filename)
    end

    # @see Nanoc3::Extra::VCS#move
    def move(src, dst)
      FileUtils.move(src, dst)
    end

  end

end
