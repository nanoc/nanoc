# frozen_string_literal: true

module Nanoc
  module Int
    class Compiler
      module Phases
        class Write < Abstract
          include Nanoc::Core::ContractsSupport

          def initialize(compiled_content_store:, wrapped:)
            super(wrapped: wrapped)

            @compiled_content_store = compiled_content_store
          end

          contract Nanoc::Core::ItemRep, C::KeywordArgs[is_outdated: C::Bool], C::Func[C::None => C::Any] => C::Any
          def run(rep, is_outdated:) # rubocop:disable Lint/UnusedMethodArgument
            yield

            writer = Nanoc::Int::ItemRepWriter.new
            writer.write_all(rep, @compiled_content_store)
          end
        end
      end
    end
  end
end
