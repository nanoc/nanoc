# frozen_string_literal: true

describe 'GH-1216', site: true, stdio: true do
  before do
    FileUtils.mkdir_p('content/talks')
    File.write('content/talks/aaa.html', 'A')
    File.write('content/talks/bbb.html', 'B')
    File.write('content/talks.html', '<%= @items.find_all("/talks/*").map { |i| i.raw_content + "=" + i[:status].to_s }.sort.join(" ") %>')

    File.write('Rules', <<~EOS)
      compile '/**/*' do
        filter :erb
        write ext: 'html'
      end
    EOS

    Nanoc::CLI.run(%w[compile])
  end

  context 'attributes changed using #[]=' do
    before do
      File.write('Rules', <<~EOS)
        preprocess do
          @items['/talks/aaa.*'][:status] = 'archived'
          @items['/talks/bbb.*'][:status] = 'archived'
        end

        compile '/**/*' do
          filter :erb
          write ext: 'html'
        end
      EOS
    end

    it 'changes output file' do
      expect { Nanoc::CLI.run(%w[compile]) }
        .to change { File.read('output/talks.html') }
        .from('A= B=')
        .to('A=archived B=archived')
    end
  end

  context 'attributes changed using update_attributes' do
    before do
      File.write('Rules', <<~EOS)
        preprocess do
          @items['/talks/aaa.*'].update_attributes(status: 'archived')
          @items['/talks/bbb.*'].update_attributes(status: 'archived')
        end

        compile '/**/*' do
          filter :erb
          write ext: 'html'
        end
      EOS
    end

    it 'changes output file' do
      expect { Nanoc::CLI.run(%w[compile]) }
        .to change { File.read('output/talks.html') }
        .from('A= B=')
        .to('A=archived B=archived')
    end
  end

  context 'raw content changed' do
    before do
      File.write('Rules', <<~EOS)
        preprocess do
          @items['/talks/aaa.*'][:status] = 'archived'
          @items['/talks/bbb.*'][:status] = 'current'
          @items['/talks/aaa.*'].raw_content = 'AAH'
        end

        compile '/**/*' do
          filter :erb
          write ext: 'html'
        end
      EOS
    end

    it 'changes output file' do
      expect { Nanoc::CLI.run(%w[compile]) }
        .to change { File.read('output/talks.html') }
        .from('A= B=')
        .to('AAH=archived B=current')
    end
  end
end
