# encoding: utf-8

module Nanoc3::Extra::VCSes

  autoload 'Bazaar',     'nanoc3/extra/vcses/bazaar'
  autoload 'Dummy',      'nanoc3/extra/vcses/dummy'
  autoload 'Git',        'nanoc3/extra/vcses/git'
  autoload 'Mercurial',  'nanoc3/extra/vcses/mercurial'
  autoload 'Subversion', 'nanoc3/extra/vcses/subversion'

  Nanoc3::Extra::VCS.register '::Nanoc3::Extra::VCSes::Bazaar',     :bazaar, :bzr
  Nanoc3::Extra::VCS.register '::Nanoc3::Extra::VCSes::Dummy',      :dummy
  Nanoc3::Extra::VCS.register '::Nanoc3::Extra::VCSes::Git',        :git
  Nanoc3::Extra::VCS.register '::Nanoc3::Extra::VCSes::Mercurial',  :mercurial, :hg
  Nanoc3::Extra::VCS.register '::Nanoc3::Extra::VCSes::Subversion', :subversion, :svn

end
