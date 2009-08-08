# encoding: utf-8

module Nanoc3::ArrayExtensions

  def symbolize_keys
    inject([]) do |array, element|
      array + [ element.respond_to?(:symbolize_keys) ? element.symbolize_keys : element ]
    end
  end

  def stringify_keys
    inject([]) do |array, element|
      array + [ element.respond_to?(:stringify_keys) ? element.symbolize_keys : element ]
    end
  end

end

class Array
  include Nanoc3::ArrayExtensions
end
