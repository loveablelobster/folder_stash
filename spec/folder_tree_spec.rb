# frozen_string_literal: true

module FolderStash
  RSpec.describe FolderTree do
    include_context 'with variables'

    let(:folders) do
      5.times.inject([dir]) do |dirs, i|
        dirs << File.join(dirs.last, "folder_#{i + 1}")
      end
    end

    let(:folder) { folders.last }

    let(:folder_tree) { described_class.for_path(folder, root: dir, limit: 4) }

    # Set-up test folder tree.
    before do
      FileUtils.mkdir_p folder
      idx = 5
      folders[0..-2].each do |f|
        2.times do
          idx += 1
          FileUtils.mkdir File.join(f, "folder_#{idx}")
        end
      end
      3.times { |i| FileUtils.touch File.join(folder, "example_#{i}.txt") }
    end

    # Delete test folder tree.
    after { FileUtils.rm_r Dir.glob("#{dir}/*") }

    describe '#available_folder' do
      subject(:available_folder) { folder_tree.available_folder }

      context 'when terminal is available' do
        it do
          expect(available_folder)
            .to have_attributes path: end_with(folders[5])
        end
      end

      context 'when terminal is not available' do
        before { FileUtils.touch File.join(folder, 'example_4.txt') }

        it do
          expect(available_folder)
            .to have_attributes path: end_with(folders[4])
        end
      end

      context 'when `folder_2` is available' do
        before do
          idx = 20
          folders[3..-2].each do |f|
            idx += 1
            FileUtils.mkdir File.join(f, "folder_#{idx}")
          end
          FileUtils.touch File.join(folder, 'example_4.txt')
        end

        it do
          expect(available_folder)
            .to have_attributes path: end_with(folders[2])
        end
      end

      context 'when none is available' do
        before do
          idx = 20
          folders[0..-2].each do |f|
            idx += 1
            FileUtils.mkdir File.join(f, "folder_#{idx}")
          end
          FileUtils.touch File.join(folder, 'example_4.txt')
        end

        it { is_expected.to be_nil }
      end
    end

    describe '#folders' do
      subject(:tree_folders) { folder_tree.folders }

      it do
        expect(tree_folders)
          .to include an_object_having_attributes(path: end_with(folders[0])),
                      an_object_having_attributes(path: end_with(folders[1])),
                      an_object_having_attributes(path: end_with(folders[2])),
                      an_object_having_attributes(path: end_with(folders[3])),
                      an_object_having_attributes(path: end_with(folders[4])),
                      an_object_having_attributes(path: end_with(folders[5]))
      end

      it do
        expect(tree_folders)
          .to all have_attributes(limit: 4)
      end
    end

    describe '#levels_below(folder)' do
      subject(:levels_below) { folder_tree.levels_below start_folder }

      context 'when folder is root' do
        let(:start_folder) { folder_tree.root }

        it { is_expected.to be 5 }
      end

      context 'when folder is `folder_2`' do
        let(:start_folder) { folder_tree.folders[2] }

        it { is_expected.to be 3 }
      end

      context 'when folder is terminal' do
        let(:start_folder) { folder_tree.terminal }

        it { is_expected.to be 0 }
      end
    end

    describe '#new_branch_in(folder)' do
      subject(:branch) { folder_tree.new_branch_in start_folder }

      context 'when trying to branch in terminal' do
        let(:start_folder) { folder_tree.folders.last }

        it do
          expect { branch }.to raise_error Errors::BranchError
        end
      end

      context 'when branching in `folder_2`' do
        let(:start_folder) { folder_tree.folders[2] }

        it 'returns the path to the created terminal directory in an array' do
          expect(branch)
            .to include(folder_tree.terminal.path)
        end

        it 'creates the terminal directory with all parents' do
          expect(File.directory?(branch.first)).to be_truthy
        end
      end
    end

    describe '#path_length' do
      subject { folder_tree.path_length }

      it { is_expected.to be 5 }
    end

    describe '#root' do
      subject(:tree_root) { folder_tree.root }

      it do
        expect(tree_root).to have_attributes path: end_with(dir)
      end
    end
  end
end

# folder_21
