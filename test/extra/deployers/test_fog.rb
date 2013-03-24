# encoding: utf-8

class Nanoc::Extra::Deployers::FogTest < Nanoc::TestCase

  def test_run
    if_have 'fog' do
      # Create deployer
      fog = Nanoc::Extra::Deployers::Fog.new(
        'output/',
        {
          :bucket     => 'mybucket',
          :provider   => 'local',
          :local_root => 'mylocalcloud'})

      # Create site
      FileUtils.mkdir_p('output')
      File.open('output/meow', 'w') { |io| io.write "I am a cat!" }
      File.open('output/bark', 'w') { |io| io.write "I am a dog!" }

      # Create local cloud (but not bucket)
      FileUtils.mkdir_p('mylocalcloud')

      # Run
      fog.run

      # Check
      assert File.file?('mylocalcloud/mybucket/meow')
      assert File.file?('mylocalcloud/mybucket/bark')
      assert_equal "I am a cat!", File.read('mylocalcloud/mybucket/meow')
      assert_equal "I am a dog!", File.read('mylocalcloud/mybucket/bark')
    end
  end

  def test_run_with_dry_run
    if_have 'fog' do
      begin
        # Create deployer
        fog = Nanoc::Extra::Deployers::Fog.new(
          'output/',
          {
            :provider              => 'aws',
            # FIXME bucket is necessary for deployer but fog doesn't like it
            :bucket_name           => 'doesntmatter',
            :aws_access_key_id     => 'meh',
            :aws_secret_access_key => 'dontcare'},
          :dry_run => true)

        # Create site
        FileUtils.mkdir_p('output')
        File.open('output/meow', 'w') { |io| io.write "I am a cat!" }
        File.open('output/bark', 'w') { |io| io.write "I am a dog!" }

        # Create local cloud (but not bucket)
        FileUtils.mkdir_p('mylocalcloud')

        # Run
        fog.run
      ensure
        # Hack :(
        ::Fog.instance_eval { @mocking = false }
      end
    end
  end

  def test_run_delete_stray
    if_have 'fog' do
      # Create deployer
      fog = Nanoc::Extra::Deployers::Fog.new(
        'output/',
        {
          :bucket     => 'mybucket',
          :provider   => 'local',
          :local_root => 'mylocalcloud'})

      # Setup fake local cloud
      FileUtils.mkdir_p('mylocalcloud/mybucket')
      File.open('mylocalcloud/mybucket/etc', 'w')  { |io| io.write('meh-etc')  }
      File.open('mylocalcloud/mybucket/meow', 'w') { |io| io.write('meh-meow') }
      File.open('mylocalcloud/mybucket/bark', 'w') { |io| io.write('meh-bark') }

      # Create site
      FileUtils.mkdir_p('output')
      File.open('output/meow', 'w') { |io| io.write "I am a cat!" }
      File.open('output/bark', 'w') { |io| io.write "I am a dog!" }

      # Create local cloud (but not bucket)
      FileUtils.mkdir_p('mylocalcloud')

      # Run
      fog.run

      # Check
      refute File.file?('mylocalcloud/mybucket/etc')
      assert File.file?('mylocalcloud/mybucket/meow')
      assert File.file?('mylocalcloud/mybucket/bark')
      assert_equal "I am a cat!", File.read('mylocalcloud/mybucket/meow')
      assert_equal "I am a dog!", File.read('mylocalcloud/mybucket/bark')
    end
  end

end
