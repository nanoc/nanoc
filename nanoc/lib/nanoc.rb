# frozen_string_literal: true

# Load external dependencies
require 'addressable'
require 'colored'
require 'ddplugin'
require 'json'
require 'parallel'

module Nanoc
end

# Load general requirements
require 'cgi'
require 'digest'
require 'English'
require 'fileutils'
require 'forwardable'
require 'logger'
require 'net/http'
require 'net/https'
require 'open3'
require 'pathname'
require 'set'
require 'singleton'
require 'stringio'
require 'tempfile'
require 'time'
require 'timeout'
require 'tmpdir'
require 'tty-which'
require 'uri'

# Load extracted Nanoc dependencies
require 'nanoc-core'
require 'nanoc-cli'
require 'nanoc-checking'
require 'nanoc-deploying'

# Re-export from Nanoc::Core
Nanoc::Identifier = Nanoc::Core::Identifier
Nanoc::DataSource = Nanoc::Core::DataSource
Nanoc::Filter = Nanoc::Core::Filter
Nanoc::Error = Nanoc::Core::Error
Nanoc::Check = Nanoc::Checking::Check
Nanoc::Pattern = Nanoc::Core::Pattern

# Load Nanoc
require 'nanoc/version'
require 'nanoc/checking'
require 'nanoc/extra'
require 'nanoc/data_sources'
require 'nanoc/filters'
require 'nanoc/helpers'
require 'nanoc/rule_dsl'
