require 'helper'

class Nanoc::RuleDSL::ActionProviderTest < Nanoc::TestCase
  def new_action_provider(site)
    rules_collection = Nanoc::RuleDSL::RulesCollection.new

    action_sequence_calculator =
      Nanoc::RuleDSL::ActionSequenceCalculator.new(
        rules_collection: rules_collection, site: site,
      )

    action_provider = Nanoc::RuleDSL::ActionProvider.new(
      rules_collection, action_sequence_calculator
    )

    Nanoc::RuleDSL::RulesLoader.new(site.config, rules_collection).load

    action_provider
  end

  def test_per_rules_file_preprocessor
    # Create site
    Nanoc::CLI.run %w[create_site foo]
    FileUtils.cd('foo') do
      # Create a bonus rules file
      File.write(
        'more_rules.rb',
        "preprocess { @items['/index.*'][:preprocessed] = true }",
      )

      # Adjust normal rules file
      File.write(
        'Rules',
        "include_rules 'more_rules'\n\npreprocess {}\n\n" + File.read('Rules'),
      )

      # Create site and compiler
      site = Nanoc::Int::SiteLoader.new.new_from_cwd
      action_provider = new_action_provider(site)

      # Check that the two preprocess blocks have been added
      assert_equal 2, action_provider.rules_collection.preprocessors.size
      refute_nil action_provider.rules_collection.preprocessors.first
      refute_nil action_provider.rules_collection.preprocessors.to_a.last

      # Apply preprocess blocks
      action_provider.preprocess(site)
      assert site.items['/index.*'].attributes[:preprocessed]
    end
  end

  def test_per_rules_file_postprocessor
    # Create site
    Nanoc::CLI.run %w[create_site foo]
    FileUtils.cd('foo') do
      # Create a bonus rules file
      File.write(
        'more_rules.rb',
        'postprocess {}',
      )

      # Adjust normal rules file
      File.write(
        'Rules',
        "include_rules 'more_rules'\n\npostprocess {}\n\n" + File.read('Rules'),
      )

      # Create site and compiler
      site = Nanoc::Int::SiteLoader.new.new_from_cwd
      action_provider = new_action_provider(site)

      # Check that the two postprocess blocks have been added
      assert_equal 2, action_provider.rules_collection.postprocessors.size
      refute_nil action_provider.rules_collection.postprocessors.first
      refute_nil action_provider.rules_collection.postprocessors.to_a.last
    end
  end
end
