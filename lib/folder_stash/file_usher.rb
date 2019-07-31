# frozen_string_literal: true

module FolderStash
  #
  class FileUsher
    # The directory
    attr_reader :directory

    def initialize(dir, nesting: 2, items: 1000)
      raise NoDirectoryError, dir: dir unless File.directory? dir

      @directory = dir
      @nesting = nesting
      @items_per_dir = items
    end

    def current_dir
      # return dir for symlink if symlink exists
      #
      # create symlink
    end

    def store(file); end
  end
end
