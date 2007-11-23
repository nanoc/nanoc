class Array

  # Pushes the object on the stack, yields, and pops stack
  def pushing(obj)
    push(obj)
    yield
  ensure
    pop
  end

end
