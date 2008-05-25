class String

  # Transforms string into an actual path
  def cleaned_path
    "/#{self}/".gsub(/^\/+|\/+$/, '/')
  end

end
