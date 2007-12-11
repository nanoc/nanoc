class String

  # Returns true if the string ends with str
  def ends_with?(str)
    str == self[-str.length, str.length]
  end

end
