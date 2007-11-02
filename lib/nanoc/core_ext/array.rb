class Array

  # Ensures that the array contains only one element
  def ensure_single(a_noun, a_context)
    if self.size != 1
      $stderr.puts "ERROR: expected 1 #{a_noun}, found #{self.size} (#{a_context})" unless $quiet
      exit(1)
    end
  end

  # Pushes the object on the stack, yields, and pops stack
  def pushing(obj)
    push(obj)
    yield
  ensure
    pop
  end

end
