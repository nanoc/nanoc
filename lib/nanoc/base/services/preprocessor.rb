module Nanoc::Int
  class Preprocessor
    def initialize(site, action_provider)
      @site = site
      @action_provider = action_provider
    end

    def run
      context = new_preprocessor_context(@site)
      @action_provider.preprocess(@site, context)

      Nanoc::Int::Site.new(
        config: context.config.unwrap,
        code_snippets: @site.code_snippets,
        items: context.items.unwrap,
        layouts: context.layouts.unwrap,
      )
    end

    def new_preprocessor_context(site)
      dependency_tracker = Nanoc::Int::DependencyTracker::Null.new
      view_context =
        Nanoc::ViewContext.new(
          reps: nil,
          items: nil,
          dependency_tracker: dependency_tracker,
          compiler: nil,
        )

      Nanoc::Int::Context.new(
        config: Nanoc::MutableConfigView.new(
          site.config,
          view_context),
        items: Nanoc::MutableItemCollectionView.new(
          IdentifiableCollectionWithModifications.new(site.items),
          view_context),
        layouts: Nanoc::MutableLayoutCollectionView.new(
          IdentifiableCollectionWithModifications.new(site.layouts),
          view_context),
      )
    end
  end

  class IdentifiableCollectionWrapper
    include Enumerable

    def initialize(wrapped)
      @wrapped = wrapped
    end

    def each
      @wrapped.each { |e| yield(e) }
      self
    end

    def size
      to_a.size
    end

    def freeze
      super.tap { @wrapped.freeze }
    end

    def frozen?
      @wrapped.frozen?
    end

    def [](arg)
      @wrapped[arg]
    end

    def to_a
      each_with_object([]) { |e, m| m << e }
    end

    def empty?
      to_a.empty?
    end
  end

  class CachedIdentifiableCollectionWrapper < IdentifiableCollectionWrapper
    def to_a
      @__cached_to_a ||= super
    end
  end

  class IdentifiableCollectionWithDeletion < CachedIdentifiableCollectionWrapper
    def initialize(wrapped, deleted_identifiers)
      super(wrapped)
      @deleted_identifiers = deleted_identifiers
    end

    def each
      @wrapped.each do |e|
        yield(e) unless @deleted_identifiers.include?(e.identifier)
      end
    end

    def [](arg)
      res = @wrapped[arg]

      if res && @deleted_identifiers.include?(res.identifier)
        nil
      else
        res
      end
    end
  end

  class IdentifiableCollectionWithAddition < CachedIdentifiableCollectionWrapper
    def initialize(wrapped, new_object)
      super(wrapped)
      @new_object = new_object
    end

    def each
      @wrapped.each { |e| yield(e) }
      yield(@new_object)
      self
    end

    def [](arg)
      res = @wrapped[arg]
      if res
        res
      else
        all = IdentifiableCollection.new(config).tap { |c| c << @new_object }
        all[arg]
      end
    end
  end

  class IdentifiableCollectionWithModifications < IdentifiableCollectionWrapper
    def delete_if(&_block)
      deleted_identifiers =
        @wrapped.lazy.select { |o| yield(o) }.map(&:identifier)

      @wrapped = IdentifiableCollectionWithDeletion.new(
        @wrapped, deleted_identifiers)
    end

    def <<(o)
      @wrapped = IdentifiableCollectionWithAddition.new(
        @wrapped, o)
    end
  end
end
