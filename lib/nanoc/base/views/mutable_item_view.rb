# frozen_string_literal: true

module Nanoc
  class MutableItemView < Nanoc::ItemWithoutRepsView
    include Nanoc::MutableDocumentViewMixin
  end
end
