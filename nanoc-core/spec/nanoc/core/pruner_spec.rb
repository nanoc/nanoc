# frozen_string_literal: true

describe Nanoc::Core::Pruner, stdio: true do
  subject(:pruner) { described_class.new(config, reps, dry_run:, exclude:) }

  let(:config) { Nanoc::Core::Configuration.new(hash: {}, dir: Dir.getwd).with_defaults }
  let(:dry_run) { false }
  let(:exclude) { [] }

  let(:reps) do
    Nanoc::Core::ItemRepRepo.new.tap do |reps|
      reps << Nanoc::Core::ItemRep.new(item, :default).tap do |rep|
        rep.raw_paths = { last: [Dir.getwd + '/output/asdf.html'] }
      end

      reps << Nanoc::Core::ItemRep.new(item, :text).tap do |rep|
        rep.raw_paths = { last: [Dir.getwd + '/output/asdf.txt'] }
      end
    end
  end

  let(:item) { Nanoc::Core::Item.new('asdf', {}, '/a.md') }

  describe '#filename_excluded?' do
    subject { pruner.filename_excluded?(filename) }

    let(:filename) { Dir.getwd + '/output/foo/bar.html' }

    context 'nothing excluded' do
      it { is_expected.to be(false) }
    end

    context 'matching identifier component excluded' do
      let(:exclude) { ['foo'] }

      it { is_expected.to be(true) }
    end

    context 'non-matching identifier component excluded' do
      let(:exclude) { ['xyz'] }

      it { is_expected.to be(false) }
    end

    context 'output dir excluded' do
      let(:exclude) { ['output'] }

      it { is_expected.to be(false) }
    end
  end

  describe '#run' do
    subject { pruner.run }

    describe 'it removes stray files' do
      let(:present_files) do
        [
          'output/foo.html',
          'output/foo.txt',
          'output/bar.html',
          'output/foo/bar.html',
          'output/foo/bar.txt',
          'output/output/asdf.txt',
        ]
      end

      let(:reps) do
        Nanoc::Core::ItemRepRepo.new.tap do |reps|
          reps << Nanoc::Core::ItemRep.new(item, :a).tap do |rep|
            rep.raw_paths = { last: [Dir.getwd + '/output/foo.html'] }
          end

          reps << Nanoc::Core::ItemRep.new(item, :b).tap do |rep|
            rep.raw_paths = { last: [Dir.getwd + '/output/bar.html'] }
          end

          reps << Nanoc::Core::ItemRep.new(item, :c).tap do |rep|
            rep.raw_paths = { last: [Dir.getwd + '/output/foo/bar.html'] }
          end
        end
      end

      before do
        present_files.each do |fn|
          FileUtils.mkdir_p(File.dirname(fn))
          File.write(fn, 'asdf')
        end
      end

      context 'nothing excluded' do
        it 'removes /foo.txt' do
          expect { subject }
            .to change { File.file?('output/foo.txt') }
            .from(true)
            .to(false)
        end

        it 'removes /foo/bar.txt' do
          expect { subject }
            .to change { File.file?('output/foo/bar.txt') }
            .from(true)
            .to(false)
        end

        it 'removes /output/asdf.txt' do
          expect { subject }
            .to change { File.file?('output/output/asdf.txt') }
            .from(true)
            .to(false)
        end
      end

      context 'foo excluded' do
        let(:exclude) { ['foo'] }

        it 'removes /foo.txt' do
          expect { subject }
            .to change { File.file?('output/foo.txt') }
            .from(true)
            .to(false)
        end

        it 'keeps /foo/bar.txt' do
          expect { subject }
            .not_to change { File.file?('output/foo/bar.txt') }
            .from(true)
        end

        it 'removes /output/asdf.txt' do
          expect { subject }
            .to change { File.file?('output/output/asdf.txt') }
            .from(true)
            .to(false)
        end
      end

      context 'output excluded' do
        let(:exclude) { ['output'] }

        it 'removes /foo.txt' do
          expect { subject }
            .to change { File.file?('output/foo.txt') }
            .from(true)
            .to(false)
        end

        it 'removes /foo/bar.txt' do
          expect { subject }
            .to change { File.file?('output/foo/bar.txt') }
            .from(true)
            .to(false)
        end

        it 'keeps /output/asdf.txt' do
          expect { subject }
            .not_to change { File.file?('output/output/asdf.txt') }
            .from(true)
        end
      end
    end

    describe 'it removes empty directories' do
      let(:present_dirs) do
        [
          'output/.foo',
          'output/foo',
          'output/foo/bar',
          'output/bar',
          'output/output',
          'output/output/asdf',
        ]
      end

      before do
        present_dirs.each do |fn|
          FileUtils.mkdir_p(fn)
        end
      end

      context 'nothing excluded' do
        it 'removes /.foo' do
          expect { subject }
            .to change { File.directory?('output/.foo') }
            .from(true)
            .to(false)
        end

        it 'removes /foo' do
          expect { subject }
            .to change { File.directory?('output/foo') }
            .from(true)
            .to(false)
        end

        it 'removes /foo/bar' do
          expect { subject }
            .to change { File.directory?('output/foo/bar') }
            .from(true)
            .to(false)
        end

        it 'removes /bar' do
          expect { subject }
            .to change { File.directory?('output/bar') }
            .from(true)
            .to(false)
        end

        it 'removes /output' do
          expect { subject }
            .to change { File.directory?('output/output') }
            .from(true)
            .to(false)
        end

        it 'removes /output/asdf' do
          expect { subject }
            .to change { File.directory?('output/output/asdf') }
            .from(true)
            .to(false)
        end
      end

      context 'foo excluded' do
        let(:exclude) { ['foo'] }

        it 'removes /.foo' do
          expect { subject }
            .to change { File.directory?('output/.foo') }
            .from(true)
            .to(false)
        end

        it 'removes /bar' do
          expect { subject }
            .to change { File.directory?('output/bar') }
            .from(true)
            .to(false)
        end

        it 'keeps /foo' do
          expect { subject }
            .not_to change { File.directory?('output/foo') }
            .from(true)
        end

        it 'keeps /foo/bar' do
          expect { subject }
            .not_to change { File.directory?('output/foo/bar') }
            .from(true)
        end

        it 'removes /output' do
          expect { subject }
            .to change { File.directory?('output/output') }
            .from(true)
            .to(false)
        end

        it 'removes /output/asdf' do
          expect { subject }
            .to change { File.directory?('output/output/asdf') }
            .from(true)
            .to(false)
        end
      end

      context 'output excluded' do
        let(:exclude) { ['output'] }

        it 'removes /.foo' do
          expect { subject }
            .to change { File.directory?('output/.foo') }
            .from(true)
            .to(false)
        end

        it 'removes /bar' do
          expect { subject }
            .to change { File.directory?('output/bar') }
            .from(true)
            .to(false)
        end

        it 'removes /foo' do
          expect { subject }
            .to change { File.directory?('output/foo') }
            .from(true)
            .to(false)
        end

        it 'removes /foo/bar' do
          expect { subject }
            .to change { File.directory?('output/foo/bar') }
            .from(true)
            .to(false)
        end

        it 'keeps /output' do
          expect { subject }
            .not_to change { File.directory?('output/output') }
            .from(true)
        end

        it 'keeps /output/asdf' do
          expect { subject }
            .not_to change { File.directory?('output/output/asdf') }
            .from(true)
        end
      end
    end
  end

  describe '#pathname_components' do
    subject { pruner.pathname_components(pathname) }

    context 'regular path' do
      let(:pathname) { Pathname.new('/a/bb/ccc/dd/e') }

      it { is_expected.to eql(%w[/ a bb ccc dd e]) }
    end
  end

  describe '#files_and_dirs_in' do
    subject { pruner.files_and_dirs_in('output/') }

    before do
      FileUtils.mkdir_p('output/projects')
      FileUtils.mkdir_p('output/.git')

      File.write('output/asdf.html', '<p>text</p>')
      File.write('output/.htaccess', 'secret stuff here')
      File.write('output/projects/nanoc.html', '<p>Nanoc is v cool!!</p>')
      File.write('output/.git/HEAD', 'some content here')
    end

    context 'nothing excluded' do
      let(:exclude) { [] }

      it 'returns all files' do
        files = [
          'output/asdf.html',
          'output/.htaccess',
          'output/projects/nanoc.html',
          'output/.git/HEAD',
        ]
        expect(subject[0]).to match_array(files)
      end

      it 'returns all directories' do
        dirs = [
          'output/projects',
          'output/.git',
        ]
        expect(subject[1]).to match_array(dirs)
      end
    end

    context 'directory (.git) excluded' do
      let(:exclude) { ['.git'] }

      it 'returns all files' do
        files = [
          'output/asdf.html',
          'output/.htaccess',
          'output/projects/nanoc.html',
        ]
        expect(subject[0]).to match_array(files)
      end

      it 'returns all directories' do
        dirs = [
          'output/projects',
        ]
        expect(subject[1]).to match_array(dirs)
      end
    end

    context 'file (.htaccess) excluded' do
      let(:exclude) { ['.htaccess'] }

      it 'returns all files' do
        files = [
          'output/asdf.html',
          'output/projects/nanoc.html',
          'output/.git/HEAD',
        ]
        expect(subject[0]).to match_array(files)
      end

      it 'returns all directories' do
        dirs = [
          'output/projects',
          'output/.git',
        ]
        expect(subject[1]).to match_array(dirs)
      end
    end

    context 'output dir is a symlink' do
      before do
        FileUtils.mv('output', 'output-real')
        File.symlink('output-real', 'output')
        if Nanoc::Core.on_windows?
          skip 'Symlinks to output dirs are currently not supported on Windows.'
        end
      end

      it 'returns all files' do
        files = [
          'output/asdf.html',
          'output/.htaccess',
          'output/projects/nanoc.html',
          'output/.git/HEAD',
        ]
        expect(subject[0]).to match_array(files)
      end

      it 'returns all directories' do
        dirs = [
          'output/projects',
          'output/.git',
        ]
        expect(subject[1]).to match_array(dirs)
      end
    end
  end
end
