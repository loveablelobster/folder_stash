# frozen_string_literal: true

RSpec.shared_context 'with variables', shared_context: :metadata do
  # Directories
  let(:dir) { 'spec/test_dir' }
  let(:folder) { folders.last }

  let(:folders) do
    5.times.inject([dir]) do |dirs, i|
      dirs << File.join(dirs.last, "folder_#{i + 1}")
    end
  end
end

# FIXME: move to own source file
def make_test_dir
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
