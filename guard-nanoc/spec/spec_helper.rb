# frozen_string_literal: true

require_relative '../../common/spec/spec_helper_head'

require 'guard-nanoc'

require_relative '../../common/spec/spec_helper_foot'

RSpec.configure do |config|
  # Swallow stdout/stderr
  config.around do |example|
    old_stdout = $stdout
    old_stderr = $stderr

    $stdout = StringIO.new
    $stderr = StringIO.new

    begin
      example.run
    ensure
      $stdout = old_stdout
      $stderr = old_stderr
    end
  end
end
