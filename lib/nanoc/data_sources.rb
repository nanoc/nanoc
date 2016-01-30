# @api private
module Nanoc::DataSources
end

require_relative 'data_sources/filesystem'

Nanoc::DataSource.register ::Nanoc::DataSources::Filesystem, :filesystem
Nanoc::DataSource.register ::Nanoc::DataSources::Filesystem, :filesystem_unified
