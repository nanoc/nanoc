# frozen_string_literal: true

require_relative '../../common/spec/spec_helper_head'
require_relative '../../common/spec/spec_helper_foot'

# Eww!
require 'timeout'
RSpec.configure do |c|
  c.around do |ex|
    puts "*** start #{ex.full_description}"
    Timeout.timeout(10) { ex.run }
    puts "*** end #{ex.full_description}"
  end
end
