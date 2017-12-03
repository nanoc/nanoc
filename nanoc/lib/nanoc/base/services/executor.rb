# frozen_string_literal: true

module Nanoc
  module Int
    class Executor
      class OutputNotWrittenError < ::Nanoc::Error
        def initialize(filter_name, output_filename)
          super("The #{filter_name.inspect} filter did not write anything to the required output file, #{output_filename}.")
        end
      end

      def initialize(rep, compilation_context, dependency_tracker)
        @rep = rep
        @compilation_context = compilation_context
        @dependency_tracker = dependency_tracker
      end

      def filter(filter_name, filter_args = {})
        filter = filter_for_filtering(@rep, filter_name)

        begin
          Nanoc::Int::NotificationCenter.post(:filtering_started, @rep, filter_name)

          # Run filter
          last = @compilation_context.snapshot_repo.get(@rep, :last)
          source = last.binary? ? last.filename : last.string
          filter_args.freeze
          result = filter.setup_and_run(source, filter_args)
          last =
            if filter.class.to_binary?
              Nanoc::Int::BinaryContent.new(filter.output_filename).tap(&:freeze)
            else
              Nanoc::Int::TextualContent.new(result).tap(&:freeze)
            end

          # Store
          @compilation_context.snapshot_repo.set(@rep, :last, last)

          # Check whether file was written
          if filter.class.to_binary? && !File.file?(filter.output_filename)
            raise OutputNotWrittenError.new(filter_name, filter.output_filename)
          end
        ensure
          Nanoc::Int::NotificationCenter.post(:filtering_ended, @rep, filter_name)
        end
      end

      def layout(layout_identifier, extra_filter_args = nil)
        layout = find_layout(layout_identifier)
        filter_name, filter_args = *@compilation_context.filter_name_and_args_for_layout(layout)
        if filter_name.nil?
          raise Nanoc::Int::Errors::Generic, "Cannot find rule for layout matching #{layout_identifier}"
        end
        filter_args = filter_args.merge(extra_filter_args || {})
        filter_args.freeze

        # Check whether item can be laid out
        last = @compilation_context.snapshot_repo.get(@rep, :last)
        raise Nanoc::Int::Errors::CannotLayoutBinaryItem.new(@rep) if last.binary?

        # Create filter
        klass = Nanoc::Filter.named!(filter_name)
        view_context = @compilation_context.create_view_context(@dependency_tracker)
        layout_view = Nanoc::LayoutView.new(layout, view_context)
        filter = klass.new(assigns_for(@rep).merge(layout: layout_view))

        # Visit
        @dependency_tracker.bounce(layout, raw_content: true)

        begin
          Nanoc::Int::NotificationCenter.post(:filtering_started, @rep, filter_name)

          # Layout
          content = layout.content
          arg = content.binary? ? content.filename : content.string
          res = filter.setup_and_run(arg, filter_args)

          # Store
          last = Nanoc::Int::TextualContent.new(res).tap(&:freeze)
          @compilation_context.snapshot_repo.set(@rep, :last, last)
        ensure
          Nanoc::Int::NotificationCenter.post(:filtering_ended, @rep, filter_name)
        end
      end

      def snapshot(snapshot_name)
        last = @compilation_context.snapshot_repo.get(@rep, :last)
        @compilation_context.snapshot_repo.set(@rep, snapshot_name, last)
      end

      def assigns_for(rep)
        @compilation_context.assigns_for(rep, @dependency_tracker)
      end

      def layouts
        @compilation_context.site.layouts
      end

      def find_layout(arg)
        req_id = arg.__nanoc_cleaned_identifier
        layout = layouts.find { |l| l.identifier == req_id }
        return layout if layout

        if use_globs?
          pat = Nanoc::Int::Pattern.from(arg)
          layout = layouts.find { |l| pat.match?(l.identifier) }
          return layout if layout
        end

        raise Nanoc::Int::Errors::UnknownLayout.new(arg)
      end

      def filter_for_filtering(rep, filter_name)
        klass = Nanoc::Filter.named!(filter_name)

        last = @compilation_context.snapshot_repo.get(@rep, :last)
        if klass.from_binary? && !last.binary?
          raise Nanoc::Int::Errors::CannotUseBinaryFilter.new(rep, klass)
        elsif !klass.from_binary? && last.binary?
          raise Nanoc::Int::Errors::CannotUseTextualFilter.new(rep, klass)
        end

        klass.new(assigns_for(rep))
      end

      def use_globs?
        @compilation_context.site.config[:string_pattern_type] == 'glob'
      end
    end
  end
end
