module Nanoc::StringExtensions

  # Transforms string into an actual path
  def cleaned_path
    "/#{self}/".gsub(/^\/+|\/+$/, '/')
  end

end

class String
  include Nanoc::StringExtensions
end
