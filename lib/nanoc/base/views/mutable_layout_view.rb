# frozen_string_literal: true

module Nanoc
  class MutableLayoutView < Nanoc::LayoutView
    include Nanoc::MutableDocumentViewMixin
  end
end
