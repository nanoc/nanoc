class Nanoc::CLI::Commands::DeployTest < Nanoc::TestCase
  def test_deploy
    skip_unless_have_command 'rsync'
    with_site do |_site|
      File.open('nanoc.yaml', 'w') do |io|
        io.write "deploy:\n"
        io.write "  public:\n"
        io.write "    kind: rsync\n"
        io.write '    dst: mydestination'
      end

      FileUtils.mkdir_p('output')
      File.open('output/blah.html', 'w') { |io| io.write 'moo' }

      Nanoc::CLI.run %w( deploy -t public )

      assert File.directory?('mydestination')
      assert File.file?('mydestination/blah.html')
    end
  end

  def test_deploy_with_dry_run
    with_site do |_site|
      File.open('nanoc.yaml', 'w') do |io|
        io.write "deploy:\n"
        io.write "  public:\n"
        io.write "    kind: rsync\n"
        io.write '    dst: mydestination'
      end

      FileUtils.mkdir_p('output')
      File.open('output/blah.html', 'w') { |io| io.write 'moo' }

      Nanoc::CLI.run %w( deploy -t public -n )

      refute File.directory?('mydestination')
      refute File.file?('mydestination/blah.html')
    end
  end

  def test_deploy_with_list_without_config
    with_site do |_site|
      FileUtils.mkdir_p('output')
      File.open('output/blah.html', 'w') { |io| io.write 'moo' }

      ios = capturing_stdio do
        Nanoc::CLI.run %w( deploy -L )
      end

      assert ios[:stdout].include?('No deployment configurations.')

      refute File.directory?('mydestination')
      refute File.file?('mydestination/blah.html')
    end
  end

  def test_deploy_with_list
    with_site do |_site|
      File.open('nanoc.yaml', 'w') do |io|
        io.write "deploy:\n"
        io.write "  public:\n"
        io.write "    kind: rsync\n"
        io.write '    dst: mydestination'
      end

      FileUtils.mkdir_p('output')
      File.open('output/blah.html', 'w') { |io| io.write 'moo' }

      ios = capturing_stdio do
        Nanoc::CLI.run %w( deploy -L )
      end

      assert ios[:stdout].include?('Available deployment configurations:')

      refute File.directory?('mydestination')
      refute File.file?('mydestination/blah.html')
    end
  end

  def test_deploy_with_list_deployers
    with_site do |_site|
      File.open('nanoc.yaml', 'w') do |io|
        io.write "deploy:\n"
        io.write "  public:\n"
        io.write "    kind: rsync\n"
        io.write '    dst: mydestination'
      end

      FileUtils.mkdir_p('output')
      File.open('output/blah.html', 'w') { |io| io.write 'moo' }

      ios = capturing_stdio do
        Nanoc::CLI.run %w( deploy -D )
      end

      assert ios[:stdout].include?('Available deployers:')

      refute File.directory?('mydestination')
      refute File.file?('mydestination/blah.html')
    end
  end

  def test_deploy_without_kind
    skip_unless_have_command 'rsync'
    with_site do |_site|
      File.open('nanoc.yaml', 'w') do |io|
        io.write "deploy:\n"
        io.write "  public:\n"
        io.write '    dst: mydestination'
      end

      FileUtils.mkdir_p('output')
      File.open('output/blah.html', 'w') { |io| io.write 'moo' }

      ios = capturing_stdio do
        Nanoc::CLI.run %w( deploy -t public )
      end

      assert ios[:stderr].include?('Warning: The specified deploy target does not have a kind attribute. Assuming rsync.')

      assert File.directory?('mydestination')
      assert File.file?('mydestination/blah.html')
    end
  end

  def test_deploy_without_target_without_default
    with_site do |_site|
      File.open('nanoc.yaml', 'w') do |io|
        io.write "deploy:\n"
        io.write "  public:\n"
        io.write '    dst: mydestination'
      end

      FileUtils.mkdir_p('output')
      File.open('output/blah.html', 'w') { |io| io.write 'moo' }

      capturing_stdio do
        err = assert_raises Nanoc::Int::Errors::GenericTrivial do
          Nanoc::CLI.run %w( deploy )
        end
        assert_equal 'The site has no deployment configuration for default.', err.message
      end
    end
  end

  def test_deploy_without_target_with_default
    skip_unless_have_command 'rsync'
    with_site do |_site|
      File.open('nanoc.yaml', 'w') do |io|
        io.write "deploy:\n"
        io.write "  default:\n"
        io.write '    dst: mydestination'
      end

      FileUtils.mkdir_p('output')
      File.open('output/blah.html', 'w') { |io| io.write 'moo' }

      capturing_stdio do
        Nanoc::CLI.run %w( deploy )
      end

      assert File.directory?('mydestination')
      assert File.file?('mydestination/blah.html')
    end
  end

  def test_deploy_with_preprocessor
    skip_unless_have_command 'rsync'
    with_site do |_site|
      File.open('nanoc.yaml', 'w') do |io|
        io.write "deploy:\n"
        io.write "  default:\n"
        io.write '    dst: mydestination'
      end

      FileUtils.mkdir_p('output')
      File.open('output/blah.html', 'w') { |io| io.write 'moo' }

      File.write('Rules', "preprocess do ; @config[:deploy][:default][:dst] = 'otherdestination' ; end\n\n" + File.read('Rules'))

      capturing_stdio do
        Nanoc::CLI.run %w( deploy )
      end

      refute File.directory?('mydestination')
      refute File.file?('mydestination/blah.html')
      assert File.directory?('otherdestination')
      assert File.file?('otherdestination/blah.html')
    end
  end
end
