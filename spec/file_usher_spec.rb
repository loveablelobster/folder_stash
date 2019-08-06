# frozen_string_literal: true

module FolderStash
  RSpec.describe FileUsher do
    include_context 'with variables'

    let(:usher) { described_class.new dir, folder_limit: 4 }
    let(:symlink) { File.join dir, FileUsher::CURRENT_STORE_PATH }

    let :ls do
      -> { Dir.new(dir).children.reject { |fn| fn.start_with? '.' } }
    end

    after do
      files = Dir.glob("#{dir}/*").push(usher.current_directory)
      FileUtils.rm_r files
    end

    context 'when initialized' do
      subject(:initialze_usher) { usher }

      context 'when the current_store_path symlink exists' do
        before do
          make_test_dir
          td = 'spec/test_dir/folder_1/folder_2/folder_3/folder_4/folder_5'
          FileUtils.ln_s File.expand_path(td), File.join(dir, FileUsher::CURRENT_STORE_PATH)
        end

        it 'does not change the existing subdirectories' do
          expect { initialze_usher }.to not_change { ls.call }
        end
      end

      context 'when the current_store_path symlink doesn not exist' do
        it "creates the '#{FileUsher::CURRENT_STORE_PATH}' symlink"\
           " in its directory" do
          expect { initialze_usher }.to change { File.exist? symlink }
            .from(be_falsey)
            .to be_truthy
        end

        it 'creates a subdirectory in its directory' do
          expect { initialze_usher }.to change { ls.call }
            .from(be_empty).to include a_random_hex_8_string
        end

        it "points the #{FileUsher::CURRENT_STORE_PATH} symlink to a"\
           " nested subdirectory" do
          nested_dirs = lambda do
            return unless File.exist? symlink

            linked_path = File.readlink(symlink).split('/')
            dir_path = File.expand_path(dir).split('/')
            linked_path - dir_path
          end

          expect { initialze_usher }.to change { nested_dirs.call }
            .from(be_nil).to contain_exactly a_random_hex_8_string,
                                             a_random_hex_8_string
        end
      end
    end

    describe '#current_directory' do
      subject { usher.current_directory }

      it { is_expected.to end_with FileUsher::CURRENT_STORE_PATH }
    end

    describe '#current_folder' do
      subject { usher.current_folder }

      it 'is returns a Folder'
    end

    describe '#current_path'

    describe '#linked_path'
  end
end
