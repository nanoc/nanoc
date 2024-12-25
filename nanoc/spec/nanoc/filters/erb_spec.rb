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
        '<%= "I was hiding in #{@location}." %>',
      )
      expect(result).to eq('I was hiding in a cheap motel.')
    end

    it 'can access assign through instance method' do
      result = filter.setup_and_run(
        '<%= "I was hiding in #{location}." %>',
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
        '<%= "I was hiding in #{@content}." %>',
      )
      expect(result).to eq('I was hiding in a cheap motel.')
    end

    it 'can access assign through instance method' do
      result = filter.setup_and_run(
        '<%= "I was hiding in #{content}." %>',
      )
      expect(result).to eq('I was hiding in a cheap motel.')
    end

    it 'can access assign through yield' do
      result = filter.setup_and_run(
        '<%= "I was hiding in #{yield}." %>',
      )
      expect(result).to eq('I was hiding in a cheap motel.')
    end
  end

  context 'locals' do
    let(:filter) { described_class.new }
    let(:params) { { locals: { location: 'a cheap motel' } } }

    it 'can access assign through instance variable' do
      result = filter.setup_and_run(
        '<%= "I was hiding in #{@location}." %>',
        params,
      )
      expect(result).to eq('I was hiding in a cheap motel.')
    end

    it 'can access assign through instance method' do
      result = filter.setup_and_run(
        '<%= "I was hiding in #{location}." %>',
        params,
      )
      expect(result).to eq('I was hiding in a cheap motel.')
    end
  end

  context 'error' do
    subject do
      filter.setup_and_run('<% raise "boom %>')
    end

    let(:filter) { described_class.new(layout:) }

    let(:layout) { Nanoc::Core::Layout.new('asdf', {}, '/default.erb') }

    example do
      error =
        begin
          subject
        rescue SyntaxError => e
          e
        end

      expect(error.message).to start_with('layout /default.erb:1:')
      expect(error.message).to include('unterminated string meets end of file')
    end
  end

  context 'with trim mode' do
    subject do
      filter.setup_and_run('% res[:success] = true', params)
    end

    let(:filter) { described_class.new }

    let(:res) { { success: false } }

    context 'trim mode unchanged' do
      let(:params) do
        {
          locals: { res: },
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
          locals: { res: },
        }
      end

      it 'honors trim mode' do
        expect { subject }.to change { res[:success] }.from(false).to(true)
      end
    end
  end
end
