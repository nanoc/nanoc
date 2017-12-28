# frozen_string_literal: true

describe Nanoc::Filters::ERB do
  context 'no assigns' do
    let(:filter) { described_class.new }

    example do
      result = filter.setup_and_run('[<%= @foo %>]')
      expect(result).to eq('[]')
    end
  end

  context 'simple assigns' do
    let(:filter) { described_class.new(location: 'a cheap motel') }

    it 'can access assign through instance variable' do
      result = filter.setup_and_run(
        '<%= "I was hiding in #{@location}." %>', # rubocop:disable Lint/InterpolationCheck
      )
      expect(result).to eq('I was hiding in a cheap motel.')
    end

    it 'can access assign through instance method' do
      result = filter.setup_and_run(
        '<%= "I was hiding in #{location}." %>', # rubocop:disable Lint/InterpolationCheck
      )
      expect(result).to eq('I was hiding in a cheap motel.')
    end

    it 'does not accept yield' do
      expect { filter.setup_and_run('<%= yield %>') }
        .to raise_error(LocalJumpError)
    end
  end

  context 'content assigns' do
    let(:filter) { described_class.new(content: 'a cheap motel') }

    it 'can access assign through instance variable' do
      result = filter.setup_and_run(
        '<%= "I was hiding in #{@content}." %>', # rubocop:disable Lint/InterpolationCheck
      )
      expect(result).to eq('I was hiding in a cheap motel.')
    end

    it 'can access assign through instance method' do
      result = filter.setup_and_run(
        '<%= "I was hiding in #{content}." %>', # rubocop:disable Lint/InterpolationCheck
      )
      expect(result).to eq('I was hiding in a cheap motel.')
    end

    it 'can access assign through yield' do
      result = filter.setup_and_run(
        '<%= "I was hiding in #{yield}." %>', # rubocop:disable Lint/InterpolationCheck
      )
      expect(result).to eq('I was hiding in a cheap motel.')
    end
  end

  context 'locals' do
    let(:filter) { described_class.new }
    let(:params) { { locals: { location: 'a cheap motel' } } }

    it 'can access assign through instance variable' do
      result = filter.setup_and_run(
        '<%= "I was hiding in #{@location}." %>', # rubocop:disable Lint/InterpolationCheck
        params,
      )
      expect(result).to eq('I was hiding in a cheap motel.')
    end

    it 'can access assign through instance method' do
      result = filter.setup_and_run(
        '<%= "I was hiding in #{location}." %>', # rubocop:disable Lint/InterpolationCheck
        params,
      )
      expect(result).to eq('I was hiding in a cheap motel.')
    end
  end

  context 'error' do
    let(:filter) { described_class.new(layout: layout) }

    let(:layout) { Nanoc::Int::Layout.new('asdf', {}, '/default.erb') }

    subject do
      filter.setup_and_run('<% raise "boom %>')
    end

    example do
      error =
        begin
          subject
        rescue SyntaxError => e
          e
        end

      expect(error.message).to start_with('layout /default.erb:1: unterminated string meets end of file')
    end
  end

  context 'with trim mode' do
    let(:filter) { described_class.new }

    let(:res) { { success: false } }

    subject do
      filter.setup_and_run('% res[:success] = true', params)
    end

    context 'trim mode unchanged' do
      let(:params) do
        {
          locals: { res: res },
        }
      end

      it 'honors trim mode' do
        expect { subject }.not_to change { res[:success] }
      end
    end

    context 'trim mode set' do
      let(:params) do
        {
          trim_mode: '%',
          locals: { res: res },
        }
      end

      it 'honors trim mode' do
        expect { subject }.to change { res[:success] }.from(false).to(true)
      end
    end
  end

  context 'safe level' do
    let(:filter) { described_class.new }

    let(:res) { { success: false } }

    subject do
      filter.setup_and_run('<%= eval File.read("moo") %>', params)
    end

    before do
      File.write('moo', '1+2')
    end

    context 'safe level unchanged' do
      let(:params) { {} }

      it 'honors safe level' do
        expect(subject).to eq('3')
      end
    end

    context 'safe level set' do
      let(:params) { { safe_level: 1 } }

      it 'honors safe level' do
        expect { subject }.to raise_error(SecurityError)
      end
    end
  end
end
