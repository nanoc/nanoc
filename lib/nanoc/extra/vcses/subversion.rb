module Nanoc::VCSes

  class Subversion < Nanoc::VCS

    identifiers :subversion, :svn

    def add(filename)
      system('svn', 'add', filename)
    end

    def remove(filename)
      system('svn', 'rm', filename)
    end

     def move(src, dst)
      system('svn', 'mv', src, dst)
    end

  end

end
