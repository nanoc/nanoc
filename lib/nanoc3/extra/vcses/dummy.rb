module Nanoc3::Extra::VCSes

  class Dummy < Nanoc3::Extra::VCS

    identifier :dummy

    def add(filename)
    end

    def remove(filename)
      FileUtils.rm_rf(filename)
    end

    def move(src, dst)
      FileUtils.move(src, dst)
    end

  end

end
