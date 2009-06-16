# encoding: utf-8

module Nanoc3::DataSources

  autoload 'Filesystem',         'nanoc3/data_sources/filesystem'
  autoload 'FilesystemCombined', 'nanoc3/data_sources/filesystem_combined'
  autoload 'FilesystemCommon',   'nanoc3/data_sources/filesystem_common'

  Nanoc3::DataSource.register '::Nanoc3::DataSources::Filesystem',         :filesystem
  Nanoc3::DataSource.register '::Nanoc3::DataSources::FilesystemCombined', :filesystem_combined

end
