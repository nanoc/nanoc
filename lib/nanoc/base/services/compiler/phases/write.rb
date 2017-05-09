module Nanoc::Int::Compiler::Phases
  class Write < Abstract
    include Nanoc::Int::ContractsSupport

    STOP = Object.new

    def initialize(snapshot_repo:, wrapped:)
      super(wrapped: wrapped)

      @snapshot_repo = snapshot_repo

      @queue = SizedQueue.new(100)
      @threads = 3.times.map do
        Thread.new do
          loop do
            e = @queue.pop
            case e
            when STOP
              break
            else
              e.call
            end
          end
        end
      end
    end

    contract Nanoc::Int::ItemRep, C::KeywordArgs[is_outdated: C::Bool], C::Func[C::None => C::Any] => C::Any
    def run(rep, is_outdated:) # rubocop:disable Lint/UnusedMethodArgument
      yield

      @queue << -> { Nanoc::Int::ItemRepWriter.new.write_all(rep, @snapshot_repo) }
    end

    def finalize
      @threads.size.times { @queue << STOP }
      @threads.each(&:join)
    end
  end
end
