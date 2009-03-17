module Nanoc3::Extra::VCSes

  class Git < Nanoc3::Extra::VCS

    identifier :git

    def add(filename)
      system('git', 'add', filename)
    end

    def remove(filename)
      system('git', 'rm', filename)
    end

    def move(src, dst)
      system('git', 'mv', src, dst)
    end

  end

end
