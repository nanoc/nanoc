module Nanoc
  class ItemWithRepsView < ::Nanoc::ItemWithoutRepsView
    include Nanoc::WithRepsViewMixin
  end
end
