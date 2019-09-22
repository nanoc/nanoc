# frozen_string_literal: true

module Nanoc
  module Base
    class LayoutView < ::Nanoc::Base::View
      include Nanoc::Base::DocumentViewMixin
    end
  end
end
