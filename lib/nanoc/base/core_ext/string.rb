module Nanoc::StringExtensions

  # Transforms string into an actual identifier
  def cleaned_identifier
    "/#{self}/".gsub(/^\/+|\/+$/, '/')
  end

end

class String
  include Nanoc::StringExtensions
end
