# frozen_string_literal: true

module Nanoc
  class ItemWithRepsView < ::Nanoc::ItemWithoutRepsView
    include Nanoc::WithRepsViewMixin
  end
end
