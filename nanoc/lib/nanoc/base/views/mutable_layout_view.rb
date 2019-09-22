# frozen_string_literal: true

module Nanoc
  module Base
    class MutableLayoutView < Nanoc::Base::LayoutView
      include Nanoc::Base::MutableDocumentViewMixin
    end
  end
end
