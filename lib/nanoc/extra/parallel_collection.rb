# frozen_string_literal: true

require 'thread'

module Nanoc::Extra
  # @api private
  class ParallelCollection
    STOP = Object.new

    include Nanoc::Int::ContractsSupport

    contract C::RespondTo[:each], C::KeywordArgs[parallelism: Integer] => C::Any
    def initialize(enum, parallelism: 2)
      @enum = enum
      @parallelism = parallelism
    end

    contract C::Func[C::Any => C::Any] => self
    def each
      queue = SizedQueue.new(2 * @parallelism)
      error = nil

      threads = (1..@parallelism).map do
        Thread.new do
          loop do
            begin
              elem = queue.pop
              break if error
              break if STOP.equal?(elem)
              yield elem
            rescue => err
              error = err
              break
            end
          end
        end
      end

      @enum.each { |e| queue << e }
      @parallelism.times { queue << STOP }

      threads.each(&:join)

      raise error if error
      self
    end

    contract C::Func[C::Any => C::Any] => C::RespondTo[:each]
    def map
      [].tap do |all|
        mutex = Mutex.new
        each do |e|
          res = yield(e)
          mutex.synchronize { all << res }
        end
      end
    end
  end
end
