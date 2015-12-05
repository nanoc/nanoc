module Nanoc
  module Int
    class Executor
      class OutputNotWrittenError < ::Nanoc::Error
        def initialize(filter_name, output_filename)
          super("The #{filter_name.inspect} filter did not write anything to the required output file, #{output_filename}.")
        end
      end

      def initialize(compiler)
        @compiler = compiler
      end

      def filter(rep, filter_name, filter_args = {})
        # Get filter class
        klass = Nanoc::Filter.named(filter_name)
        raise Nanoc::Int::Errors::UnknownFilter.new(filter_name) if klass.nil?

        # Check whether filter can be applied
        if klass.from_binary? && !rep.binary?
          raise Nanoc::Int::Errors::CannotUseBinaryFilter.new(rep, klass)
        elsif !klass.from_binary? && rep.binary?
          raise Nanoc::Int::Errors::CannotUseTextualFilter.new(rep, klass)
        end

        begin
          # Notify start
          Nanoc::Int::NotificationCenter.post(:filtering_started, rep, filter_name)

          # Create filter
          filter = klass.new(assigns_for(rep))

          # Run filter
          last = rep.snapshot_contents[:last]
          source = rep.binary? ? last.filename : last.string
          result = filter.setup_and_run(source, filter_args)
          if klass.to_binary?
            rep.snapshot_contents[:last] = Nanoc::Int::BinaryContent.new(filter.output_filename).tap(&:freeze)
          else
            rep.snapshot_contents[:last] = Nanoc::Int::TextualContent.new(result).tap(&:freeze)
          end

          # Check whether file was written
          if klass.to_binary? && !File.file?(filter.output_filename)
            raise OutputNotWrittenError.new(filter_name, filter.output_filename)
          end

          # Create snapshot
          snapshot(rep, rep.snapshot_contents[:post] ? :post : :pre, final: false) unless rep.binary?
        ensure
          # Notify end
          Nanoc::Int::NotificationCenter.post(:filtering_ended, rep, filter_name)
        end
      end

      def layout(rep, layout_identifier, extra_filter_args = nil)
        layout = find_layout(layout_identifier)
        filter_name, filter_args = @compiler.rules_collection.filter_for_layout(layout)
        if filter_name.nil?
          raise Nanoc::Int::Errors::Generic, "Cannot find rule for layout matching #{layout_identifier}"
        end
        filter_args = filter_args.merge(extra_filter_args || {})

        # Check whether item can be laid out
        raise Nanoc::Int::Errors::CannotLayoutBinaryItem.new(rep) if rep.binary?

        # Create "pre" snapshot
        if rep.snapshot_contents[:post].nil?
          snapshot(rep, :pre, final: true)
        end

        # Create filter
        klass = Nanoc::Filter.named(filter_name)
        raise Nanoc::Int::Errors::UnknownFilter.new(filter_name) if klass.nil?
        filter = klass.new(assigns_for(rep).merge({ layout: layout }))

        # Visit
        Nanoc::Int::NotificationCenter.post(:visit_started, layout)
        Nanoc::Int::NotificationCenter.post(:visit_ended,   layout)

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
        @compiler.assigns_for(rep)
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

      def use_globs?
        @compiler.site.config[:string_pattern_type] == 'glob'
      end
    end
  end
end
