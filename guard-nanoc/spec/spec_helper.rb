# frozen_string_literal: true

require_relative '../../common/spec/spec_helper_head'

module Guard
  # `guard-compat` defines `Notifier` as a module rather than a class. We define
  # `Notifier` as a class here, before requiring guard-compat and guard, so that
  # `guard` does not break.
  class Notifier
  end
end

require 'guard/compat/test/helper'
require 'guard/nanoc'

require_relative '../../common/spec/spec_helper_foot'

ENV['__NANOC_DEV_LIVE_DISABLE_VIEW'] = '1'

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
