# frozen_string_literal: true

module FolderStash
  RSpec.describe FileUsher do
    let(:usher) { described_class.new dir }
    let(:dir) { 'spec/test_dir' }

    it { p usher }
  end
end
