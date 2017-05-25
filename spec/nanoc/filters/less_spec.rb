# frozen_string_literal: true

describe Nanoc::Filters::Less, site: true, stdio: true do
  # These tests are high-level in order to interact well with the compiler. This is important for
  # this :less filter, because of the way it handles fibers.

  before do
    File.open('Rules', 'w') do |io|
      io.write "compile '/**/*.less' do\n"
      io.write "  filter :less\n"
      io.write "  write item.identifier.without_ext + '.css'\n"
      io.write "end\n"
    end
  end

  context 'one file' do
    let(:content_a) { 'p { color: red; }' }

    before do
      File.write('content/a.less', content_a)
    end

    it 'compiles a.less' do
      Nanoc::CLI.run(%w[compile])
      expect(File.read('output/a.css')).to match(/^p\s*\{\s*color:\s*red;?\s*\}/)
    end

    context 'with compression' do
      let(:content_a) { '.foo { bar: a; } .bar { foo: b; }' }

      before do
        File.open('Rules', 'w') do |io|
          io.write "compile '/*.less' do\n"
          io.write "  filter :less, compress: true\n"
          io.write "  write item.identifier.without_ext + '.css'\n"
          io.write "end\n"
        end
      end

      it 'compiles and compresses a.less' do
        Nanoc::CLI.run(%w[compile])
        expect(File.read('output/a.css')).to match(/^\.foo\{bar:a\}\n?\.bar\{foo:b\}/)
      end
    end
  end

  context 'two files' do
    let(:content_a) { '@import "b.less";' }
    let(:content_b) { 'p { color: red; }' }

    before do
      File.write('content/a.less', content_a)
      File.write('content/b.less', content_b)
    end

    it 'compiles a.less' do
      Nanoc::CLI.run(%w[compile])
      expect(File.read('output/a.css')).to match(/^p\s*\{\s*color:\s*red;?\s*\}/)
    end

    it 'recompiles a.less if b.less has changed' do
      Nanoc::CLI.run(%w[compile])

      File.write('content/b.less', 'p { color: blue; }')

      Nanoc::CLI.run(%w[compile])
      expect(File.read('output/a.css')).to match(/^p\s*\{\s*color:\s*blue;?\s*\}/)
    end
  end

  context 'paths relative to site directory' do
    let(:content_a) { '@import "content/foo/bar/imported_file.less";' }
    let(:content_b) { 'p { color: red; }' }

    before do
      FileUtils.mkdir_p('content/foo/bar')

      File.write('content/a.less', content_a)
      File.write('content/foo/bar/imported_file.less', content_b)
    end

    it 'compiles a.less' do
      Nanoc::CLI.run(%w[compile])
      expect(File.read('output/a.css')).to match(/^p\s*\{\s*color:\s*red;?\s*\}/)
    end

    it 'recompiles a.less if b.less has changed' do
      Nanoc::CLI.run(%w[compile])

      File.write('content/foo/bar/imported_file.less', 'p { color: blue; }')

      Nanoc::CLI.run(%w[compile])
      expect(File.read('output/a.css')).to match(/^p\s*\{\s*color:\s*blue;?\s*\}/)
    end
  end

  context 'paths relative to current file' do
    let(:content_a) { '@import "bar/imported_file.less";' }
    let(:content_b) { 'p { color: red; }' }

    before do
      FileUtils.mkdir_p('content/foo/bar')

      File.write('content/foo/a.less', content_a)
      File.write('content/foo/bar/imported_file.less', content_b)
    end

    it 'compiles a.less' do
      Nanoc::CLI.run(%w[compile])
      expect(File.read('output/foo/a.css')).to match(/^p\s*\{\s*color:\s*red;?\s*\}/)
    end

    it 'recompiles a.less if b.less has changed' do
      Nanoc::CLI.run(%w[compile])

      File.write('content/foo/bar/imported_file.less', 'p { color: blue; }')

      Nanoc::CLI.run(%w[compile])
      expect(File.read('output/foo/a.css')).to match(/^p\s*\{\s*color:\s*blue;?\s*\}/)
    end
  end
end
