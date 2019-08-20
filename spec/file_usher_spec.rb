# frozen_string_literal: true

module FolderStash
  RSpec.describe FileUsher do
    include_context 'with variables'

    let :usher do
      described_class.new dir, folder_limit: 4, link_location: 'spec'
    end

    let(:path_rxp) { %r{test_dir/([0-9a-z]{16}/){2}test_file[0-9]*.txt$} }
    let(:symlink) { File.join 'spec', FileUsher::CURRENT_STORE_PATH }

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
          FileUtils.ln_s File.expand_path(td), symlink
        end

        it 'does not change the existing subdirectories' do
          expect { initialze_usher }.to(not_change { ls.call })
        end
      end

      context 'when the current_store_path symlink does not exist' do
        let :nested_dirs do
          lambda do
            return unless File.exist? symlink

            linked_path = File.readlink(symlink).split('/')
            dir_path = File.expand_path(dir).split('/')
            linked_path - dir_path
          end
        end

        it "creates the '#{FileUsher::CURRENT_STORE_PATH}' symlink"\
           ' in its directory' do
          expect { initialze_usher }.to change { File.exist? symlink }
            .from(be_falsey)
            .to be_truthy
        end

        it 'creates a subdirectory in its directory' do
          expect { initialze_usher }.to change(ls, :call)
            .from(be_empty).to include a_random_hex_8_string
        end

        it "points the #{FileUsher::CURRENT_STORE_PATH} symlink to a"\
           ' nested subdirectory' do
          expect { initialze_usher }.to change(nested_dirs, :call)
            .from(be_nil).to contain_exactly a_random_hex_8_string,
                                             a_random_hex_8_string
        end
      end

      context 'when no subdirs are used' do
        subject :flat_usher do
          described_class.new dir, nesting_levels: nil,
                                   link_location: 'spec'
        end

        let(:test_file) { 'spec/test_file.txt' }

        before do
          contents = "Hi!\n\nI used to live in #{File.expand_path(dir)}."
          File.write(test_file, contents)
        end

        after { FileUtils.rm test_file if File.exist? test_file }

        it 'returns the base directory as the current path' do
          expect(flat_usher.current_path).to eq File.expand_path(dir)
        end

        it 'has no folder limit' do
          expect(flat_usher.folder_limit).to be_nil
        end

        it 'returns the base directory as the linked path' do
          expect(flat_usher.linked_path).to eq File.expand_path(dir)
        end

        it 'has no nesting levels' do
          expect(flat_usher.nesting_levels).to be_nil
        end

        it 'copies a file to the base directory' do
          expect { flat_usher.copy(test_file) }
            .to change { Dir.children(dir) }
            .from(a_collection_excluding(File.basename(test_file)))
            .to(a_collection_including(File.basename(test_file)))
            .and(not_change { File.exist? test_file })
        end

        it 'moves a file to the base directory' do
          expect { flat_usher.move(test_file) }
            .to change { Dir.children(dir) }
            .from(a_collection_excluding(File.basename(test_file)))
            .to(a_collection_including(File.basename(test_file)))
            .and change { File.exist? test_file }.from(be_truthy).to be_falsey
        end
      end
    end

    context 'when storing files' do
      subject :store_files do
        files_to_store.map { |f| usher.move f }
      end

      let :test_files do
        65.times.inject([]) { |arr, f| arr << "spec/test_file#{f + 1}.txt" }
      end

      before do
        contents = test_files.map do |f|
          "Hi!\n\n I\'m #{f}.\n\n I used to live in #{File.expand_path(dir)}."
        end
        test_files.each.with_index { |f, i| File.write(f, contents[i]) }
      end

      after do
        test_files.each { |f| FileUtils.rm f if File.exist? f }
      end

      context 'when storing within the limit' do
        let(:files_to_store) { test_files[0..63] }

        it 'stores all files in subdirectories' do
          expect(store_files.all? { |f| path_rxp.match? f }).to be_truthy
        end
      end

      context 'when exceeding the total limit' do
        let(:files_to_store) { test_files }

        let :msg do
          'The storage tree has reached the limit of allowed items: 4 items'\
          ' in 2 subdirectories (64 allowd items in total).'
        end

        it do
          expect { store_files }
            .to raise_error Errors::TreeLimitExceededError, msg
        end
      end
    end

    describe '#current_directory' do
      subject { usher.current_directory }

      it { is_expected.to end_with FileUsher::CURRENT_STORE_PATH }
    end

    describe '#current_path' do
      subject(:the_path) { usher.current_path }

      it 'returns the a path in /spec/test_dir/ and two hex(8) random'\
         ' subdirectories' do
        expect(the_path)
          .to match_regex %r{spec\/test_dir(\/[0-9a-z]{16}){2}$}
      end
    end

    describe '#linked_path' do
      subject(:linked_path) { usher.linked_path }

      it 'returns the a path in /spec/test_dir/ and two hex(8) random'\
         ' subdirectories' do
        expect(linked_path)
          .to match_regex %r{spec\/test_dir(\/[0-9a-z]{16}){2}$}
      end
    end

    describe 'copying and moving files' do
      let(:test_file) { 'spec/test_file.txt' }

      before do
        contents = "Hi!\n\nI used to live in #{File.expand_path(dir)}."
        File.write(test_file, contents)
      end

      after { FileUtils.rm test_file if File.exist? test_file }

      describe '#copy(file)' do
        context 'when renaming' do
          subject(:store_test_file) { usher.copy test_file, 'new_name.txt' }

          it { is_expected.to end_with 'new_name.txt' }
        end
      end

      describe '#move(file)' do
        subject :store_test_file do
          usher.move test_file, pathtype: pathtype
        end

        context 'when renaming' do
          subject(:store_test_file) { usher.move test_file, 'new_name.txt' }

          it { is_expected.to end_with 'new_name.txt' }
        end

        context 'when returning the absolute path' do
          let(:pathtype) { :absolute }

          it do
            expect(store_test_file)
              .to match_regex(path_rxp).and start_with File.expand_path(dir)
          end
        end

        context 'when returning the relative path' do
          let(:pathtype) { :relative }

          it do
            expect(store_test_file)
              .to match_regex(path_rxp).and start_with 'spec/test_dir'
          end
        end

        context 'when returning the tree path to the moved file' do
          let(:pathtype) { :tree }

          it do
            expect(store_test_file)
              .to match_regex(path_rxp).and start_with 'test_dir'
          end
        end
      end
    end
  end
end
