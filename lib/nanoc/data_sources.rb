# encoding: utf-8

# @api private
module Nanoc::DataSources
  autoload 'Filesystem',         'nanoc/data_sources/filesystem'
  autoload 'FilesystemUnified',  'nanoc/data_sources/filesystem_unified'
  autoload 'FilesystemVerbose',  'nanoc/data_sources/filesystem_verbose'

  Nanoc::DataSource.register '::Nanoc::DataSources::FilesystemVerbose',  :filesystem_verbose
  Nanoc::DataSource.register '::Nanoc::DataSources::FilesystemUnified',  :filesystem_unified
  Nanoc::DataSource.register '::Nanoc::DataSources::FilesystemUnified',  :filesystem
end
