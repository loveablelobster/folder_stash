# frozen_string_literal: true

module FolderStash
  RSpec.describe Folder do
    include_context 'with variables'

    let(:folder) { described_class.new folder_path, 4 }
    let(:folder_path) { File.join dir, 'folder' }

    # Set-up test folder.
    before do
      FileUtils.mkdir folder_path unless File.exist? folder_path
      3.times do |i|
        FileUtils.touch File.join folder_path, "example_#{i + 1}.txt"
        FileUtils.touch File.join folder_path, '.hidden.txt'
      end
    end

    # Delete test folder.
    after { FileUtils.rm_r folder_path if File.exist? folder_path }

    describe 'available?' do
      subject { folder.available? }

      context 'when the limit is not reached' do
        it { is_expected.to be_truthy }
      end

      context 'when the limit is reached' do
        before { FileUtils.touch File.join folder_path, 'example_4.txt'}

        it { is_expected.to be_falsey }
      end
    end

    describe 'count' do
      subject { folder.count }

      it { is_expected.to be 3 }
    end

    describe 'limit?' do
      subject { folder.limit? }

      context 'when the limit is not reached' do
        it { is_expected.to be_falsey }
      end

      context 'when the limit is reached' do
        before { FileUtils.touch File.join folder_path, 'example_4.txt'}

        it { is_expected.to be_truthy }
      end

      context 'when the limit is exceeded' do
        before do
          FileUtils.touch File.join(folder_path, 'example_4.txt')
          FileUtils.touch File.join(folder_path, 'example_5.txt')
        end

        it { is_expected.to be_truthy }
      end
    end

    describe 'entries(include_hidden: false)' do
      subject(:list) { folder.entries opts }

      context 'when excluding hidden files' do
        let(:opts) { { include_hidden: false } }

        it do
          expect(list).to contain_exactly 'example_1.txt',
                                          'example_2.txt',
                                          'example_3.txt'
        end
      end

      context 'when including hidden files' do
        let(:opts) { { include_hidden: true } }

        it do
          expect(list).to contain_exactly 'example_1.txt',
                                          'example_2.txt',
                                          'example_3.txt',
                                          '.hidden.txt'
        end
      end
    end
  end
end
