class Array

  # Ensures that the array contains only one element
  def ensure_single(a_noun, a_context)
    error "Expected 1 #{a_noun}, found #{self.size} (#{a_context})" if self.size != 1
  end

  # Pushes the object on the stack, yields, and pops stack
  def pushing(obj)
    push(obj)
    yield
  ensure
    pop
  end

end
