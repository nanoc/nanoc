module Nanoc
  module Int
    class Executor
      class OutputNotWrittenError < ::Nanoc::Error
        def initialize(filter_name, output_filename)
          super("The #{filter_name.inspect} filter did not write anything to the required output file, #{output_filename}.")
        end
      end

      def initialize(compiler, dependency_tracker)
        @compiler = compiler
        @dependency_tracker = dependency_tracker
      end

      def filter(rep, filter_name, filter_args = {})
        filter = filter_for_filtering(rep, filter_name)

        begin
          Nanoc::Int::NotificationCenter.post(:filtering_started, rep, filter_name)

          # Run filter
          last = rep.snapshot_contents[:last]
          source = rep.binary? ? last.filename : last.string
          filter_args.freeze
          result = filter.setup_and_run(source, filter_args)
          rep.snapshot_contents[:last] =
            if filter.class.to_binary?
              Nanoc::Int::BinaryContent.new(filter.output_filename).tap(&:freeze)
            else
              Nanoc::Int::TextualContent.new(result).tap(&:freeze)
            end

          # Check whether file was written
          if filter.class.to_binary? && !File.file?(filter.output_filename)
            raise OutputNotWrittenError.new(filter_name, filter.output_filename)
          end

          # Create snapshot
          snapshot(rep, rep.snapshot_contents[:post] ? :post : :pre, final: false) unless rep.binary?
        ensure
          Nanoc::Int::NotificationCenter.post(:filtering_ended, rep, filter_name)
        end
      end

      def layout(rep, layout_identifier, extra_filter_args = nil)
        layout = find_layout(layout_identifier)
        filter_name, filter_args = *@compiler.filter_name_and_args_for_layout(layout)
        if filter_name.nil?
          raise Nanoc::Int::Errors::Generic, "Cannot find rule for layout matching #{layout_identifier}"
        end
        filter_args = filter_args.merge(extra_filter_args || {})
        filter_args.freeze

        # Check whether item can be laid out
        raise Nanoc::Int::Errors::CannotLayoutBinaryItem.new(rep) if rep.binary?

        # Create "pre" snapshot
        if rep.snapshot_contents[:post].nil?
          snapshot(rep, :pre, final: true)
        end

        # Create filter
        klass = Nanoc::Filter.named(filter_name)
        raise Nanoc::Int::Errors::UnknownFilter.new(filter_name) if klass.nil?
        view_context = @compiler.create_view_context(@dependency_tracker)
        layout_view = Nanoc::LayoutView.new(layout, view_context)
        filter = klass.new(assigns_for(rep).merge({ layout: layout_view }))

        # Visit
        @dependency_tracker.bounce(layout)

        begin
          # Notify start
          Nanoc::Int::NotificationCenter.post(:processing_started, layout)
          Nanoc::Int::NotificationCenter.post(:filtering_started,  rep, filter_name)

          # Layout
          content = layout.content
          arg = content.binary? ? content.filename : content.string
          res = filter.setup_and_run(arg, filter_args)
          rep.snapshot_contents[:last] = Nanoc::Int::TextualContent.new(res).tap(&:freeze)

          # Create "post" snapshot
          snapshot(rep, :post, final: false)
        ensure
          # Notify end
          Nanoc::Int::NotificationCenter.post(:filtering_ended,  rep, filter_name)
          Nanoc::Int::NotificationCenter.post(:processing_ended, layout)
        end
      end

      def snapshot(rep, snapshot_name, final: true, path: nil) # rubocop:disable Lint/UnusedMethodArgument
        # NOTE: :path is irrelevant

        unless rep.binary?
          rep.snapshot_contents[snapshot_name] = rep.snapshot_contents[:last]
        end

        if snapshot_name == :pre && final
          rep.snapshot_defs << Nanoc::Int::SnapshotDef.new(:pre, true)
        end

        if final
          raw_path = rep.raw_path(snapshot: snapshot_name)
          if raw_path
            ItemRepWriter.new.write(rep, raw_path)
          end
        end
      end

      def assigns_for(rep)
        @compiler.assigns_for(rep, @dependency_tracker)
      end

      def layouts
        @compiler.site.layouts
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
        klass = Nanoc::Filter.named(filter_name)
        raise Nanoc::Int::Errors::UnknownFilter.new(filter_name) if klass.nil?

        if klass.from_binary? && !rep.binary?
          raise Nanoc::Int::Errors::CannotUseBinaryFilter.new(rep, klass)
        elsif !klass.from_binary? && rep.binary?
          raise Nanoc::Int::Errors::CannotUseTextualFilter.new(rep, klass)
        end

        klass.new(assigns_for(rep))
      end

      def use_globs?
        @compiler.site.config[:string_pattern_type] == 'glob'
      end
    end
  end
end
