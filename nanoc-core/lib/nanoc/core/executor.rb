# frozen_string_literal: true

module Nanoc
  module Core
    class Executor
      def initialize(rep, compilation_context, dependency_tracker)
        @rep = rep
        @compilation_context = compilation_context
        @dependency_tracker = dependency_tracker
      end

      def filter(filter_name, filter_args = {})
        filter = filter_for_filtering(filter_name)

        begin
          Nanoc::Core::NotificationCenter.post(:filtering_started, @rep, filter_name)

          # Run filter
          last = @compilation_context.compiled_content_store.get_current(@rep)
          source = last.binary? ? last.filename : last.string
          filter_args.freeze
          result = filter.setup_and_run(source, filter_args)
          last =
            if filter.class.to_binary?
              Nanoc::Core::BinaryContent.new(filter.output_filename).tap(&:freeze)
            else
              Nanoc::Core::TextualContent.new(result).tap(&:freeze)
            end

          # Store
          @compilation_context.compiled_content_store.set_current(@rep, last)
        ensure
          Nanoc::Core::NotificationCenter.post(:filtering_ended, @rep, filter_name)
        end
      end

      def layout(layout_identifier, extra_filter_args = nil)
        layout = find_layout(layout_identifier)
        filter_name_and_args = @compilation_context.filter_name_and_args_for_layout(layout)
        filter_name = filter_name_and_args.name
        if filter_name.nil?
          raise Nanoc::Core::Errors::CannotDetermineFilter.new(layout_identifier)
        end

        filter_args = filter_name_and_args.args
        filter_args = filter_args.merge(extra_filter_args || {})
        filter_args.freeze

        # Check whether item can be laid out
        last = @compilation_context.compiled_content_store.get_current(@rep)
        raise Nanoc::Core::Errors::CannotLayoutBinaryItem.new(@rep) if last.binary?

        # Create filter
        klass = Nanoc::Core::Filter.named!(filter_name)
        layout_view = Nanoc::Core::LayoutView.new(layout, view_context)
        filter = klass.new(assigns.merge(layout: layout_view))

        # Visit
        @dependency_tracker.bounce(layout, raw_content: true)

        begin
          Nanoc::Core::NotificationCenter.post(:filtering_started, @rep, filter_name)

          # Layout
          content = layout.content
          arg = content.binary? ? content.filename : content.string
          res = filter.setup_and_run(arg, filter_args)

          # Store
          last = Nanoc::Core::TextualContent.new(res).tap(&:freeze)
          @compilation_context.compiled_content_store.set_current(@rep, last)
        ensure
          Nanoc::Core::NotificationCenter.post(:filtering_ended, @rep, filter_name)
        end
      end

      def snapshot(snapshot_name)
        last = @compilation_context.compiled_content_store.get_current(@rep)
        @compilation_context.compiled_content_store.set(@rep, snapshot_name, last)
        Nanoc::Core::NotificationCenter.post(:snapshot_created, @rep, snapshot_name)
      end

      def assigns
        view_context.assigns_for(@rep, site: @compilation_context.site)
      end

      def layouts
        @compilation_context.site.layouts
      end

      def find_layout(arg)
        req_id = arg.__nanoc_cleaned_identifier
        layout = layouts.object_with_identifier(req_id)
        return layout if layout

        if use_globs?
          # TODO: use object_matching_glob instead
          pat = Nanoc::Core::Pattern.from(arg)
          layout = layouts.find { |l| pat.match?(l.identifier) }
          return layout if layout
        end

        raise Nanoc::Core::Errors::UnknownLayout.new(arg)
      end

      def filter_for_filtering(filter_name)
        klass = Nanoc::Core::Filter.named!(filter_name)

        last = @compilation_context.compiled_content_store.get_current(@rep)
        if klass.from_binary? && !last.binary?
          raise Nanoc::Core::Errors::CannotUseBinaryFilter.new(@rep, klass)
        elsif !klass.from_binary? && last.binary?
          raise Nanoc::Core::Errors::CannotUseTextualFilter.new(@rep, klass)
        end

        klass.new(assigns)
      end

      def use_globs?
        @compilation_context.site.config[:string_pattern_type] == 'glob'
      end

      def view_context
        @_view_context ||=
          Nanoc::Core::ViewContextForCompilation.new(
            reps: @compilation_context.reps,
            items: @compilation_context.site.items,
            dependency_tracker: @dependency_tracker,
            compilation_context: @compilation_context,
            compiled_content_store: @compilation_context.compiled_content_store,
          )
      end
    end
  end
end
