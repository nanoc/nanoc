# frozen_string_literal: true

class Nanoc::Int::Compiler::Stage
  def call(*args)
    Nanoc::Int::Instrumentor.call(:stage_ran, self.class) do
      run(*args)
    end
  end

  def run(*)
    raise NotImplementedError
  end
end
