# frozen_string_literal: true

module Nanoc::RuleDSL
  class CompilationRuleContext < RuleContext
    include Nanoc::Core::ContractsSupport

    contract C::KeywordArgs[
      rep: Nanoc::Int::ItemRep,
      site: Nanoc::Int::Site,
      recorder: Nanoc::RuleDSL::ActionRecorder,
      view_context: Nanoc::ViewContextForPreCompilation,
    ] => C::Any
    def initialize(rep:, site:, recorder:, view_context:)
      @_recorder = recorder

      super(rep: rep, site: site, view_context: view_context)
    end

    # Filters the current representation (calls {Nanoc::Int::ItemRep#filter} with
    # the given arguments on the rep).
    #
    # @see Nanoc::Int::ItemRep#filter
    #
    # @param [Symbol] filter_name The name of the filter to run the item
    #   representations' content through
    #
    # @param [Hash] filter_args The filter arguments that should be passed to
    #   the filter's #run method
    #
    # @return [void]
    def filter(filter_name, filter_args = {})
      @_recorder.filter(filter_name, filter_args)
    end

    # Layouts the current representation (calls {Nanoc::Int::ItemRep#layout} with
    # the given arguments on the rep).
    #
    # @see Nanoc::Int::ItemRep#layout
    #
    # @param [String] layout_identifier The identifier of the layout the item
    #   should be laid out with
    #
    # @return [void]
    def layout(layout_identifier, extra_filter_args = nil)
      @_recorder.layout(layout_identifier, extra_filter_args)
    end

    # Creates a snapshot of the current compiled item content. Calls
    # {Nanoc::Int::ItemRep#snapshot} with the given arguments on the rep.
    #
    # @see Nanoc::Int::ItemRep#snapshot
    #
    # @param [Symbol] snapshot_name The name of the snapshot to create
    #
    # @param [String, nil] path
    #
    # @return [void]
    def snapshot(snapshot_name, path: Nanoc::UNDEFINED)
      @_recorder.snapshot(snapshot_name, path: path)
    end

    # Creates a snapshot named :last the current compiled item content, with
    # the given path. This is a convenience method for {#snapshot}.
    #
    # @see #snapshot
    #
    # @param [String] arg
    #
    # @return [void]
    def write(arg)
      @_write_snapshot_counter ||= 0
      snapshot_name = "_#{@_write_snapshot_counter}".to_sym
      @_write_snapshot_counter += 1

      case arg
      when String, Nanoc::Core::Identifier, nil
        snapshot(snapshot_name, path: arg)
      when Hash
        if arg.key?(:ext)
          ext = arg[:ext].sub(/\A\./, '')
          path = @item.identifier.without_exts + '.' + ext
          snapshot(snapshot_name, path: path)
        else
          raise ArgumentError, 'Cannot call #write this way (need path or :ext)'
        end
      else
        raise ArgumentError, 'Cannot call #write this way (need path or :ext)'
      end
    end
  end
end
