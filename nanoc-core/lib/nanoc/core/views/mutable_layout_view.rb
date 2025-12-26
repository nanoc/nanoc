# frozen_string_literal: true

module Nanoc
  module Core
    class MutableLayoutView < Nanoc::Core::LayoutView
      include Nanoc::Core::MutableDocumentViewMixin
    end
  end
end
