# encoding: utf-8

module Nanoc3::DataSources

  autoload 'Delicious',          'nanoc3/data_sources/delicious'
  autoload 'Filesystem',         'nanoc3/data_sources/filesystem'
  autoload 'FilesystemCombined', 'nanoc3/data_sources/filesystem_combined'
  autoload 'FilesystemCommon',   'nanoc3/data_sources/filesystem_common'
  autoload 'FilesystemCompact',  'nanoc3/data_sources/filesystem_compact'
  autoload 'Twitter',            'nanoc3/data_sources/twitter'

  Nanoc3::DataSource.register '::Nanoc3::DataSources::Delicious',          :delicious
  Nanoc3::DataSource.register '::Nanoc3::DataSources::Filesystem',         :filesystem
  Nanoc3::DataSource.register '::Nanoc3::DataSources::FilesystemCombined', :filesystem_combined
  Nanoc3::DataSource.register '::Nanoc3::DataSources::FilesystemCompact',  :filesystem_compact
  Nanoc3::DataSource.register '::Nanoc3::DataSources::Twitter',            :twitter

end
