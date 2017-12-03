# frozen_string_literal: true

module Nanoc::Int::Compiler::Phases
end

require_relative 'phases/abstract'

require_relative 'phases/recalculate'
require_relative 'phases/cache'
require_relative 'phases/resume'
require_relative 'phases/write'
require_relative 'phases/mark_done'
