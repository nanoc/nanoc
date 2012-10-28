# encoding: utf-8

class Nanoc::CLI::Commands::CreateItemTest < MiniTest::Unit::TestCase

  include Nanoc::TestHelpers

  def test_run
    with_site do |site|
      Nanoc::CLI.run %w( create_item /blah/ )
      assert File.file?('content/blah.html')
    end
  end

  def test_alias
    with_site do |site|
      Nanoc::CLI.run %w( ci /blah/ )
      assert File.file?('content/blah.html')
    end
  end

  def test_unqualified_identifier
    with_site do |site|
      Nanoc::CLI.run %w( create-item blah )
      assert File.file?('content/blah.html')
    end
  end

  def test_duplicate_identifier
    with_site do |site|
      Nanoc::CLI.run %w( create-item blah )
      assert File.file?('content/blah.html')
      assert_raises(::Nanoc::Errors::GenericTrivial) do
        Nanoc::CLI.run %w( create-item blah )
      end
    end
  end
  
  def test_no_arguments
    with_site do |site|
      assert_raises(::Nanoc::Errors::GenericTrivial) do
        Nanoc::CLI.run %w( create-item )
      end
    end
  end

  def test_make_id_but_no_title
    with_site do |site|
      assert_raises(::Nanoc::Errors::GenericTrivial) do
        Nanoc::CLI.run %w( create-item --make-id )
      end
    end
  end

  def test_too_many_arguments
    with_site do |site|
      assert_raises(::Nanoc::Errors::GenericTrivial) do
        Nanoc::CLI.run %w( create-item id unquoted multi word title unquoted multi word content)
      end
    end
  end

  def test_too_many_arguments_make_id
    with_site do |site|
      assert_raises(::Nanoc::Errors::GenericTrivial) do
        Nanoc::CLI.run [ "create-item", "--make-id", "quoted multi word title", "quoted multi word content", "extra argument" ]
      end
    end
  end

  def test_quoted_arguments
    with_site do |site|
      Nanoc::CLI.run [ "create-item", "id", "quoted multi word title", "quoted multi word content" ]
      assert File.file?('content/id.html')
    end
  end

  def test_identifier_title
    with_site do |site|
      Nanoc::CLI.run %w( create-item id title)
      assert File.file?('content/id.html')
    end
  end

  def test_identifier_title_content
    with_site do |site|
      Nanoc::CLI.run %w( create-item id title content)
      assert File.file?('content/id.html')
    end
  end

  def test_make_id_title
    with_site do |site|
      Nanoc::CLI.run [ "create-item", "--make-id", "What's the $64,000 question?" ]
      assert File.file?('content/whats-the-64-000-question.html')
    end
  end

  def test_make_id_title_prefix
    with_site do |site|
      Nanoc::CLI.run [ "create-item", "--make-id", "--id-prefix=philosophy-", "What's the $64,000 question?" ]
      assert File.file?('content/philosophy-whats-the-64-000-question.html')
    end
  end

end
