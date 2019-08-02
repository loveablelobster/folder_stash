# frozen_string_literal: true

module FolderStash
  RSpec.describe FileUsher do
    let(:usher) { described_class.new dir }
    let(:dir) { 'spec/test_dir' }
    let(:symlink) { File.join dir, FileUsher::CURRENT_STORE_PATH }

    let :ls do
      -> { Dir.new(dir).children.reject { |fn| fn.start_with? '.' } }
    end

    context 'when initialized' do
      subject(:initialze_usher) { usher }

      after do
        files = Dir.glob("#{dir}/*").push(usher.current_directory)
        FileUtils.rm_r files
      end

      context 'when the current_store_path symlink exists' do
        before { usher }

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
            .from(be_empty).to include an_uuid
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
            .from(be_nil).to contain_exactly an_uuid, an_uuid
        end
      end
    end
  end
end
