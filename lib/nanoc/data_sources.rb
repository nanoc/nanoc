# encoding: utf-8

module Nanoc::DataSources

  autoload 'Filesystem',         'nanoc/data_sources/filesystem'
  autoload 'FilesystemUnified',  'nanoc/data_sources/filesystem_unified'
  autoload 'FilesystemVerbose',  'nanoc/data_sources/filesystem_verbose'

  Nanoc::DataSource.register '::Nanoc::DataSources::FilesystemVerbose',  :filesystem_verbose
  Nanoc::DataSource.register '::Nanoc::DataSources::FilesystemUnified',  :filesystem_unified

  # Deprecated; fetch data from online data sources manually instead
  # TODO [in nanoc 4.0] remove me
  autoload 'Delicious', 'nanoc/data_sources/deprecated/delicious'
  autoload 'LastFM',    'nanoc/data_sources/deprecated/last_fm'
  autoload 'Twitter',   'nanoc/data_sources/deprecated/twitter'
  Nanoc::DataSource.register '::Nanoc::DataSources::Delicious',          :delicious
  Nanoc::DataSource.register '::Nanoc::DataSources::LastFM',             :last_fm
  Nanoc::DataSource.register '::Nanoc::DataSources::Twitter',            :twitter

  # Deprecated; use `filesystem_verbose` or `filesystem_unified` instead
  # TODO [in nanoc 4.0] remove me
  Nanoc::DataSource.register '::Nanoc::DataSources::FilesystemVerbose',  :filesystem
  Nanoc::DataSource.register '::Nanoc::DataSources::FilesystemUnified',  :filesystem_combined
  Nanoc::DataSource.register '::Nanoc::DataSources::FilesystemUnified',  :filesystem_compact
  FilesystemCombined = FilesystemUnified
  FilesystemCompact  = FilesystemUnified

end
