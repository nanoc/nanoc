# frozen_string_literal: true

class Nanoc::Int::Compiler::Stage
  def call(*args)
    notify(:stage_started)
    res = Nanoc::Int::Instrumentor.call(:stage_ran, self.class) do
      run(*args)
    end
    notify(:stage_ended)
    res
  rescue
    notify(:stage_aborted)
    raise
  end

  def run(*)
    raise NotImplementedError
  end

  private

  def notify(sym)
    name = self.class.to_s.sub(/^.*::/, '')
    Nanoc::Core::NotificationCenter.post(sym, name)
  end
end
