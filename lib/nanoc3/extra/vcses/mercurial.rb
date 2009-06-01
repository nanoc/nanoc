# encoding: utf-8

module Nanoc3::Extra::VCSes

  class Mercurial < Nanoc3::Extra::VCS

    def add(filename)
      system('hg', 'add', filename)
    end

    def remove(filename)
      system('hg', 'rm', filename)
    end

    def move(src, dst)
      system('hg', 'mv', src, dst)
    end

  end

end
