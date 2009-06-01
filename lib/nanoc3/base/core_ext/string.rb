# encoding: utf-8

module Nanoc3::StringExtensions

  # Transforms string into an actual identifier
  def cleaned_identifier
    "/#{self}/".gsub(/^\/+|\/+$/, '/')
  end

end

class String
  include Nanoc3::StringExtensions
end
