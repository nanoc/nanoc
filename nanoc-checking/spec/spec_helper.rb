# frozen_string_literal: true

require_relative '../../common/spec/spec_helper_head'

require 'nanoc/checking'

require 'vcr'

VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  c.hook_into :webmock
end

require_relative '../../common/spec/spec_helper_foot'
