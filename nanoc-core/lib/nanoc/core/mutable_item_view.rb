# frozen_string_literal: true

module Nanoc
  module Core
    class MutableItemView < Nanoc::Core::BasicItemView
      include Nanoc::Core::MutableDocumentViewMixin
    end
  end
end
