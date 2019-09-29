# frozen_string_literal: true

module Nanoc
  module Core
    # Generic trivial error. Superclass for all Nanoc-specific errors that are
    # considered "trivial", i.e. errors that do not require a full crash report.
    class TrivialError < ::Nanoc::Core::Error
    end
  end
end
