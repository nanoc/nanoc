# encoding: utf-8

module Nanoc3::DataSources

  autoload 'Delicious',          'nanoc3/data_sources/delicious'
  autoload 'FilesystemCombined', 'nanoc3/data_sources/filesystem_combined'
  autoload 'FilesystemCompact',  'nanoc3/data_sources/filesystem_compact'
  autoload 'FilesystemVerbose',  'nanoc3/data_sources/filesystem_verbose'
  autoload 'LastFM',             'nanoc3/data_sources/last_fm'
  autoload 'Twitter',            'nanoc3/data_sources/twitter'

  Nanoc3::DataSource.register '::Nanoc3::DataSources::Delicious',          :delicious
  Nanoc3::DataSource.register '::Nanoc3::DataSources::FilesystemCombined', :filesystem_combined
  Nanoc3::DataSource.register '::Nanoc3::DataSources::FilesystemCompact',  :filesystem_compact
  Nanoc3::DataSource.register '::Nanoc3::DataSources::FilesystemVerbose',  :filesystem_verbose
  Nanoc3::DataSource.register '::Nanoc3::DataSources::LastFM',             :last_fm
  Nanoc3::DataSource.register '::Nanoc3::DataSources::Twitter',            :twitter

  # Deprecated; use filesystem_verbose instead
  # TODO [in nanoc 3.2] remove me
  Nanoc3::DataSource.register '::Nanoc3::DataSources::FilesystemVerbose',  :filesystem

end
