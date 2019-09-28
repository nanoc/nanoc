# frozen_string_literal: true

require_relative '../../common/spec/spec_helper_head'

require 'nanoc'

if Nanoc::Core.on_windows?
  warn 'nanoc-live is not currently supported on Windows'
  exit 0
end

require 'nanoc/live'

require_relative '../../common/spec/spec_helper_foot'
