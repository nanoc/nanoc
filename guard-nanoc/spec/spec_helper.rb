RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  # Swallow stdout/stderr
  config.around(:each) do |example|
    old_stdout = $stdout
    old_stderr = $stderr

    $stdout = StringIO.new
    $stderr = StringIO.new

    begin
      example.run
    ensure
      $stdout = old_stdout
      $stderr = old_stderr
    end
  end

  # In temporary site
  config.around(:each) do |example|
    Dir.mktmpdir('nanoc-test') do |dir|
      FileUtils.cd(dir) do
        Nanoc::CLI.run(%w( create-site foo ))

        FileUtils.cd('foo') do
          example.run
        end
      end
    end
  end

  config.filter_run :focus
  config.run_all_when_everything_filtered = true

  config.disable_monkey_patching!

  #config.warnings = true

  if config.files_to_run.one?
    config.default_formatter = 'doc'
  end

  #config.profile_examples = 10

  config.order = :random

  Kernel.srand config.seed
end
