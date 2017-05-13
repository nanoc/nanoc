# frozen_string_literal: true

describe Nanoc::CLI::Commands::ShowPlugins, site: true, stdio: true do
  describe '#run' do
    it 'can be invoked' do
      Nanoc::CLI.run(['show-plugins'])
    end

    context 'site with plugins' do
      before do
        File.write('lib/default.rb', 'Nanoc::Filter.define(:show_plugins_x) {}')
      end

      it 'outputs show_plugins_x under the right section' do
        expect { Nanoc::CLI.run(['show-plugins']) }
          .to output(/  custom:\n    show_plugins_x/).to_stdout
      end
    end
  end
end
