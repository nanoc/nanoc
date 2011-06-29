# encoding: utf-8

module Nanoc::Extra::VCSes

  autoload 'Bazaar',     'nanoc/extra/vcses/bazaar'
  autoload 'Dummy',      'nanoc/extra/vcses/dummy'
  autoload 'Git',        'nanoc/extra/vcses/git'
  autoload 'Mercurial',  'nanoc/extra/vcses/mercurial'
  autoload 'Subversion', 'nanoc/extra/vcses/subversion'

  Nanoc::Extra::VCS.register '::Nanoc::Extra::VCSes::Bazaar',     :bazaar, :bzr
  Nanoc::Extra::VCS.register '::Nanoc::Extra::VCSes::Dummy',      :dummy
  Nanoc::Extra::VCS.register '::Nanoc::Extra::VCSes::Git',        :git
  Nanoc::Extra::VCS.register '::Nanoc::Extra::VCSes::Mercurial',  :mercurial, :hg
  Nanoc::Extra::VCS.register '::Nanoc::Extra::VCSes::Subversion', :subversion, :svn

end
