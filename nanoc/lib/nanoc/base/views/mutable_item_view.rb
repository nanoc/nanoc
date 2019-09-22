# frozen_string_literal: true

module Nanoc
  module Base
    class MutableItemView < Nanoc::Base::BasicItemView
      include Nanoc::Base::MutableDocumentViewMixin
    end
  end
end
