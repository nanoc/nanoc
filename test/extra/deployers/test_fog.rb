class Nanoc::Extra::Deployers::FogTest < Nanoc::TestCase
  def test_run
    if_have 'fog' do
      # Create deployer
      fog = Nanoc::Extra::Deployers::Fog.new(
        'output/',
        {
          bucket: 'mybucket',
          provider: 'local',
          local_root: 'mylocalcloud' })

      # Create site
      FileUtils.mkdir_p('output')
      File.open('output/meow', 'w') { |io| io.write 'I am a cat!' }
      File.open('output/bark', 'w') { |io| io.write 'I am a dog!' }

      # Create local cloud (but not bucket)
      FileUtils.mkdir_p('mylocalcloud')

      # Run
      fog.run

      # Check
      assert File.file?('mylocalcloud/mybucket/meow')
      assert File.file?('mylocalcloud/mybucket/bark')
      assert_equal 'I am a cat!', File.read('mylocalcloud/mybucket/meow')
      assert_equal 'I am a dog!', File.read('mylocalcloud/mybucket/bark')
    end
  end

  def test_run_with_dry_run
    if_have 'fog' do
      begin
        # Create deployer
        fog = Nanoc::Extra::Deployers::Fog.new(
          'output/',
          {
            provider: 'aws',
            # FIXME: bucket is necessary for deployer but fog doesn't like it
            bucket_name: 'doesntmatter',
            aws_access_key_id: 'meh',
            aws_secret_access_key: 'dontcare' },
          dry_run: true)

        # Create site
        FileUtils.mkdir_p('output')
        File.open('output/meow', 'w') { |io| io.write 'I am a cat!' }
        File.open('output/bark', 'w') { |io| io.write 'I am a dog!' }

        # Create local cloud (but not bucket)
        FileUtils.mkdir_p('mylocalcloud')

        # Run
        fog.run
      ensure
        # FIXME: ugly hack
        ::Fog.instance_eval { @mocking = false }
      end
    end
  end

  def test_run_cdn_with_dry_run
    if_have 'fog' do
      begin
        # Create deployer
        fog = Nanoc::Extra::Deployers::Fog.new(
          'output/',
          {
            provider: 'aws',
                  cdn_id: 'id-cdn',
            # FIXME: bucket is necessary for deployer but fog doesn't like it
            bucket_name: 'doesntmatter',
            aws_access_key_id: 'meh',
            aws_secret_access_key: 'dontcare' },
          dry_run: true)

        # Create site
        FileUtils.mkdir_p('output')
        File.open('output/meow', 'w') { |io| io.write 'I am a cat!' }
        File.open('output/bark', 'w') { |io| io.write 'I am a dog!' }

        # Create local cloud (but not bucket)
        FileUtils.mkdir_p('mylocalcloud')

        # Run
        fog.run
      ensure
        # HACK :(
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
          bucket: 'mybucket',
          provider: 'local',
          local_root: 'mylocalcloud' })

      # Setup fake local cloud
      FileUtils.mkdir_p('mylocalcloud/mybucket')
      File.open('mylocalcloud/mybucket/etc', 'w')  { |io| io.write('meh-etc')  }
      File.open('mylocalcloud/mybucket/meow', 'w') { |io| io.write('meh-meow') }
      File.open('mylocalcloud/mybucket/bark', 'w') { |io| io.write('meh-bark') }

      # Create site
      FileUtils.mkdir_p('output')
      File.open('output/meow', 'w') { |io| io.write 'I am a cat!' }
      File.open('output/bark', 'w') { |io| io.write 'I am a dog!' }

      # Create local cloud (but not bucket)
      FileUtils.mkdir_p('mylocalcloud')

      # Run
      fog.run

      # Check
      refute File.file?('mylocalcloud/mybucket/etc')
      assert File.file?('mylocalcloud/mybucket/meow')
      assert File.file?('mylocalcloud/mybucket/bark')
      assert_equal 'I am a cat!', File.read('mylocalcloud/mybucket/meow')
      assert_equal 'I am a dog!', File.read('mylocalcloud/mybucket/bark')
    end
  end

  def test_upload
    if_have 'fog' do
      fog = Nanoc::Extra::Deployers::Fog.new(
        'output/', provider: 'aws')

      key_old = '__old'
      key_same = '__same'
      key_new = '__new'

      File.write(key_same, 'hallo')
      File.write(key_new, 'hallo new')

      etags = {
        key_same => '598d4c200461b81522a3328565c25f7c',
        key_new => '598d4c200461b81522a3328565c25f7c',
      }

      keys_to_destroy = [key_old, key_same, key_new]
      keys_to_invalidate = []

      s3_files = mock
      s3_files.stubs(:create)
      s3_directory = mock
      s3_directory.stubs(:files).returns(s3_files)

      # key_same
      refute fog.send(:needs_upload?, key_same, key_same, etags)
      fog.send(
        :upload, key_same, key_same, etags, keys_to_destroy, keys_to_invalidate, s3_directory)

      assert_equal([key_old, key_new], keys_to_destroy)
      assert_equal([], keys_to_invalidate)

      # key_new
      assert fog.send(:needs_upload?, key_new, key_new, etags)
      fog.send(
        :upload, key_new, key_new, etags, keys_to_destroy, keys_to_invalidate, s3_directory)

      assert_equal([key_old], keys_to_destroy)
      assert_equal([key_new], keys_to_invalidate)
    end
  end

  def test_read_etags_with_local_provider
    if_have 'fog' do
      fog = Nanoc::Extra::Deployers::Fog.new(
        'output/', provider: 'local')

      files = [
        mock('file_a'),
        mock('file_b'),
      ]

      assert_equal({}, fog.send(:read_etags, files))
    end
  end

  def test_read_etags_with_aws_provider
    if_have 'fog' do
      fog = Nanoc::Extra::Deployers::Fog.new(
        'output/', provider: 'aws')

      files = [
        mock('file_a', key: 'key_a', etag: 'etag_a'),
        mock('file_b', key: 'key_b', etag: 'etag_b'),
      ]

      expected = {
        'key_a' => 'etag_a',
        'key_b' => 'etag_b',
      }

      assert_equal(expected, fog.send(:read_etags, files))
    end
  end

  def test_calc_local_etag_with_local_provider
    if_have 'fog' do
      fog = Nanoc::Extra::Deployers::Fog.new(
        'output/', provider: 'local')

      file_path = 'blah.tmp'
      File.write(file_path, 'hallo')

      assert_nil fog.send(:calc_local_etag, file_path)
    end
  end

  def test_calc_local_etag_with_aws_provider
    if_have 'fog' do
      fog = Nanoc::Extra::Deployers::Fog.new(
        'output/', provider: 'aws')

      file_path = 'blah.tmp'
      File.write(file_path, 'hallo')

      assert_equal(
        '598d4c200461b81522a3328565c25f7c',
        fog.send(:calc_local_etag, file_path))
    end
  end

  def test_needs_upload_with_missing_remote_etag
    if_have 'fog' do
      fog = Nanoc::Extra::Deployers::Fog.new(
        'output/', provider: 'aws')

      file_path = 'blah.tmp'
      File.write(file_path, 'hallo')

      key = 'some_key'
      etags = {}

      assert fog.send(:needs_upload?, key, file_path, etags)
    end
  end

  def test_needs_upload_with_different_etags
    if_have 'fog' do
      fog = Nanoc::Extra::Deployers::Fog.new(
        'output/', provider: 'aws')

      file_path = 'blah.tmp'
      File.write(file_path, 'hallo')

      key = 'some_key'
      etags = { key => 'some_etag' }

      assert fog.send(:needs_upload?, key, file_path, etags)
    end
  end

  def test_needs_upload_with_identical_etags
    if_have 'fog' do
      fog = Nanoc::Extra::Deployers::Fog.new(
        'output/', provider: 'aws')

      file_path = 'blah.tmp'
      File.write(file_path, 'hallo')

      key = 'some_key'
      etags = { key => '598d4c200461b81522a3328565c25f7c' }

      refute fog.send(:needs_upload?, key, file_path, etags)
    end
  end
end
