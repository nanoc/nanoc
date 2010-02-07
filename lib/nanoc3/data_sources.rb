# encoding: utf-8

module Nanoc3::DataSources

  autoload 'Delicious',          'nanoc3/data_sources/delicious'
  autoload 'Filesystem',         'nanoc3/data_sources/filesystem'
  autoload 'FilesystemUnified',  'nanoc3/data_sources/filesystem_unified'
  autoload 'FilesystemVerbose',  'nanoc3/data_sources/filesystem_verbose'
  autoload 'LastFM',             'nanoc3/data_sources/last_fm'
  autoload 'Twitter',            'nanoc3/data_sources/twitter'

  Nanoc3::DataSource.register '::Nanoc3::DataSources::Delicious',          :delicious
  Nanoc3::DataSource.register '::Nanoc3::DataSources::FilesystemVerbose',  :filesystem_verbose
  Nanoc3::DataSource.register '::Nanoc3::DataSources::FilesystemUnified',  :filesystem_unified
  Nanoc3::DataSource.register '::Nanoc3::DataSources::LastFM',             :last_fm
  Nanoc3::DataSource.register '::Nanoc3::DataSources::Twitter',            :twitter

  # Deprecated; use filesystem_verbose instead
  # TODO [in nanoc 4.0] remove me
  Nanoc3::DataSource.register '::Nanoc3::DataSources::FilesystemVerbose',  :filesystem
  Nanoc3::DataSource.register '::Nanoc3::DataSources::FilesystemUnified',  :filesystem_combined
  Nanoc3::DataSource.register '::Nanoc3::DataSources::FilesystemUnified',  :filesystem_compact

  FilesystemCombined = FilesystemUnified
  FilesystemCompact  = FilesystemUnified

end
