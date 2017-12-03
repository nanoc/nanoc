# frozen_string_literal: true

module Nanoc
  class MutableItemView < Nanoc::BasicItemView
    include Nanoc::MutableDocumentViewMixin
  end
end
