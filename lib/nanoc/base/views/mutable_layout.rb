module Nanoc
  class MutableLayoutView < Nanoc::LayoutView
    # Sets the value for the given attribute.
    #
    # @param [Symbol] key
    #
    # @see Hash#[]=
    def []=(key, value)
      unwrap[key] = value
    end
  end
end
