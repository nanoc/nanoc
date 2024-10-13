# frozen_string_literal: true

require 'nanoc/spec'

def __nanoc_core_chdir(dir)
  here = Dir.getwd
  Dir.chdir(dir)
  yield
ensure
  Dir.chdir(here)
end

def __nanoc_core_with_env_vars(hash, &)
  orig_env_hash = ENV.to_hash
  hash.each_pair { |k, v| ENV[k] = v }
  yield
ensure
  orig_env_hash.each_pair { |k, v| ENV[k] = v }
end

RSpec.configure do |c|
  c.include(Nanoc::Spec::Helper)

  # TODO: Now that HelperHelper is used for filters too, maybe it is worth
  # renaming it to DataHelper or so.
  c.include(Nanoc::Spec::HelperHelper, helper: true)
  c.include(Nanoc::Spec::HelperHelper, filter: true)

  c.threadsafe = false

  # TODO: Only really relevant when using the filesystem data source
  c.before(:each, site: true) do
    FileUtils.mkdir_p('content')
    FileUtils.mkdir_p('layouts')
    FileUtils.mkdir_p('lib')
    FileUtils.mkdir_p('output')

    File.write('nanoc.yaml', '{}')

    File.write('Rules', 'passthrough "/**/*"')
  end

  c.fuubar_progress_bar_options = {
    format: '%c/%C |<%b>%i| %p%%',
  }

  c.before(:each, fork: true) do
    skip 'fork() is not supported on Windows' if Nanoc::Core.on_windows?
  end

  c.before do
    Nanoc::Core::NotificationCenter.reset
  end

  c.around do |example|
    should_chdir =
      !example.metadata.key?(:chdir) ||
      example.metadata[:chdir]

    if should_chdir
      Dir.mktmpdir('nanoc-test') do |dir|
        __nanoc_core_chdir(dir) { example.run }
      end
    else
      example.run
    end
  end

  c.around(:each, stdio: true) do |example|
    orig_stdout = $stdout
    orig_stderr = $stderr

    unless ENV['QUIET'] == 'false'
      $stdout = StringIO.new
      $stderr = StringIO.new
    end

    example.run

    $stdout = orig_stdout
    $stderr = orig_stderr
  end
end

RSpec::Matchers.define_negated_matcher :not_match, :match

RSpec::Matchers.define :send_notification do |name, *expected_args|
  supports_block_expectations

  include RSpec::Matchers::Composable

  match do |actual|
    @actual_notifications = []
    Nanoc::Core::NotificationCenter.on(name, self) do |*actual_args|
      @actual_notifications << actual_args
    end

    actual.call
    Nanoc::Core::NotificationCenter.sync

    @actual_notifications.any? { |c| c == expected_args }
  end

  description do
    "send notification #{name.inspect} with args #{expected_args.inspect}"
  end

  failure_message do |_actual|
    s = "expected that proc would send notification #{name.inspect} with args #{expected_args.inspect}"
    if @actual_notifications.any?
      s << " (received #{@actual_notifications.size} times with other arguments: #{@actual_notifications.map(&:inspect).join(', ')})"
    end
    s
  end

  failure_message_when_negated do |_actual|
    "expected that proc would not send notification #{name.inspect} with args #{expected_args.inspect}"
  end
end

RSpec::Matchers.define :raise_frozen_error do |_expected|
  match do |actual|
    actual.call
    false
  rescue => e
    if e.is_a?(RuntimeError) || e.is_a?(TypeError)
      e.message =~ /(^can't modify frozen |^unable to modify frozen object$)/
    else
      false
    end
  end

  supports_block_expectations

  failure_message do |_actual|
    'expected that proc would raise a frozen error'
  end

  failure_message_when_negated do |_actual|
    'expected that proc would not raise a frozen error'
  end
end

RSpec::Matchers.define :be_humanly_sorted do
  match do |actual|
    actual == sort(actual)
  end

  description do
    'be humanly sorted'
  end

  failure_message do |actual|
    expected_order = []
    actual.zip(sort(actual)).each do |a, b|
      if a != b
        expected_order << b
      end
    end

    "expected collection to be sorted (incorrect order: #{expected_order.join(' < ')})"
  end

  def sort(coll)
    coll.sort_by do |elem|
      elem.dup.unicode_normalize(:nfd).encode('ASCII', fallback: ->(_) { '' }).downcase
    end
  end
end

RSpec::Matchers.define :finish_in_under do |expected|
  supports_block_expectations

  match do |actual|
    before = Time.now
    actual.call
    after = Time.now
    @actual_duration = after - before
    @actual_duration < expected
  end

  chain :seconds do
  end

  failure_message do |_actual|
    "expected that proc would finish in under #{expected}s, but took #{format '%0.1fs', @actual_duration}"
  end

  failure_message_when_negated do |_actual|
    "expected that proc would not finish in under #{expected}s, but took #{format '%0.1fs', @actual_duration}"
  end
end

RSpec::Matchers.define :yield_from_fiber do |expected|
  supports_block_expectations

  include RSpec::Matchers::Composable

  match do |actual|
    @res = Fiber.new { actual.call }.resume
    values_match?(expected, @res)
  end

  description do
    "yield #{expected.inspect} from fiber"
  end

  failure_message do |_actual|
    "expected that proc would yield #{expected.inspect} from fiber, but was #{@res.inspect}"
  end

  failure_message_when_negated do |_actual|
    "expected that proc would not yield #{expected.inspect} from fiber, but was #{@res.inspect}"
  end
end

RSpec::Matchers.define :be_some_textual_content do |expected|
  include RSpec::Matchers::Composable

  match do |actual|
    actual.is_a?(Nanoc::Core::TextualContent) && values_match?(expected, actual.string)
  end

  description do
    "textual content matching #{expected.inspect}"
  end

  failure_message do |actual|
    "expected #{actual.inspect} to be textual content matching #{expected.inspect}"
  end

  failure_message_when_negated do |actual|
    "expected #{actual.inspect} not to be textual content matching #{expected.inspect}"
  end
end

RSpec::Matchers.define :be_some_binary_content do |expected|
  include RSpec::Matchers::Composable

  match do |actual|
    actual.is_a?(Nanoc::Core::BinaryContent) && values_match?(expected, File.read(actual.filename))
  end

  description do
    "binary content matching #{expected.inspect}"
  end

  failure_message do |actual|
    "expected #{actual.inspect} to be binary content matching #{expected.inspect}"
  end

  failure_message_when_negated do |actual|
    "expected #{actual.inspect} not to be binary content matching #{expected.inspect}"
  end
end

RSpec::Matchers.alias_matcher :some_textual_content, :be_some_textual_content
RSpec::Matchers.alias_matcher :some_binary_content, :be_some_binary_content

RSpec::Matchers.define :have_correct_yard_examples do |_name, *_expected_args|
  chain :in_file do |file|
    root_dir = File.expand_path(__dir__ + '/../..')
    YARD.parse(root_dir + '/' + file)
  end

  match do |actual|
    examples =
      P(actual).tags(:example).flat_map do |example|
        # Classify
        lines = example.text.lines.map do |line|
          [/^\s*# ?=>/.match?(line) ? :result : :code, line]
        end

        # Join
        pieces = []
        lines.each do |line|
          if !pieces.empty? && pieces.last.first == line.first
            pieces.last.last << line.last
          else
            pieces << line
          end
        end
        lines = pieces.map(&:last)

        # Collect
        lines.each_slice(2).to_a
      end

    b = binding
    executed_examples = examples.map do |pair|
      {
        input: pair.first,
        expected: eval(pair.last.match(/# ?=>(.*)/)[1], b),
        actual: eval(pair.first, b),
      }
    end

    @failing_examples = executed_examples.reject { |ex| ex[:expected] == ex[:actual] }

    @failing_examples.empty?
  end

  failure_message do |_actual|
    parts =
      @failing_examples.map do |ex|
        format(
          "%s\nexpected to be\n    %s\nbut was\n    %s",
          ex[:input],
          ex[:expected].inspect,
          ex[:actual].inspect,
        )
      end

    parts.join("\n\n---\n\n")
  end
end

RSpec::Matchers.define :have_a_valid_manifest do
  match do |actual|
    manifest_lines = File.readlines(actual + '.manifest').map(&:chomp).reject(&:empty?)
    gemspec_lines = eval(File.read(actual + '.gemspec'), binding, actual + '.gemspec').files

    @missing_from_manifest = gemspec_lines - manifest_lines
    @extra_in_manifest = manifest_lines - gemspec_lines

    @missing_from_manifest.empty? && @extra_in_manifest.empty?
  end

  description do
    'have a valid manifest'
  end

  failure_message do |_actual|
    reasons = []
    if @missing_from_manifest.any?
      reasons << "file(s) missing from manifest (#{@missing_from_manifest.join(', ')})"
    end
    if @extra_in_manifest.any?
      reasons << "file(s) extra in manifest (#{@extra_in_manifest.join(', ')})"
    end

    "expected manifest to be valid (problems: #{reasons.join(' and ')})"
  end
end

RSpec::Matchers.define :create_dependency_on do |expected|
  supports_block_expectations

  include RSpec::Matchers::Composable

  match do |actual|
    @to = expected
    dependency_tracker = @to._context.dependency_tracker
    dependency_store = dependency_tracker.dependency_store

    from = Nanoc::Core::Item.new('x', {}, '/x.md')

    a = dependency_store.objects_causing_outdatedness_of(from)

    begin
      dependency_tracker.enter(from)
      actual.call
    ensure
      dependency_tracker.exit
    end

    b = dependency_store.objects_causing_outdatedness_of(from)

    (b - a).include?(@to)
  end

  description do
    "create a dependency onto #{expected.inspect}"
  end

  failure_message do |_actual|
    "expected dependency to be created onto #{expected.inspect}"
  end

  failure_message_when_negated do |_actual|
    "expected no dependency to be created onto #{expected.inspect}"
  end
end

RSpec::Matchers.define :create_dependency_from do |expected|
  supports_block_expectations

  include RSpec::Matchers::Composable

  match do |actual|
    @from = expected
    dependency_tracker = @from._context.dependency_tracker
    dependency_store = dependency_tracker.dependency_store

    a = dependency_store.objects_causing_outdatedness_of(@from)

    begin
      dependency_tracker.enter(@from._unwrap)
      actual.call
    ensure
      dependency_tracker.exit
    end

    b = dependency_store.objects_causing_outdatedness_of(@from)

    @actual = b - a

    if @onto
      values_match?(@onto, @actual)
    else
      @actual.any?
    end
  end

  chain :onto do |onto|
    @onto = onto
  end

  description do
    "create a dependency from #{expected.inspect}"
  end

  failure_message do |_actual|
    "expected a dependency to be created from #{expected.inspect}#{@onto ? " onto #{@onto.inspect}" : nil}, but generated #{@actual.inspect}"
  end

  failure_message_when_negated do |_actual|
    "expected no dependency to be created from #{expected.inspect}, but generated #{@actual.inspect}"
  end
end
