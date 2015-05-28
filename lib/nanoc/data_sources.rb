# @api private
module Nanoc::DataSources
  autoload 'Filesystem',         'nanoc/data_sources/filesystem'
  autoload 'FilesystemUnified',  'nanoc/data_sources/filesystem_unified'

  Nanoc::DataSource.register '::Nanoc::DataSources::FilesystemUnified',  :filesystem_unified
  Nanoc::DataSource.register '::Nanoc::DataSources::FilesystemUnified',  :filesystem
end
