class String

  # Returns true if the string starts with str
  def starts_with?(str)
    str == self[0, str.length]
  end

  # Returns true if the string ends with str
  def ends_with?(str)
    str == self[-str.length, str.length]
  end

end
