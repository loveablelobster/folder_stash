# frozen_string_literal: true

module FolderStash
  # FileUsher stores files in a directory tree with a defined maximum number of
  # #items per directory.
  #
  # It will create new subdirectories to store files in if a subdirectory has
  # reached the maximum number of items.
  class FileUsher
    CURRENT_STORE_PATH = '.current_store_path'

    # The working directory where all subdirectories and files are stored.
    attr_reader :directory

    # The number of nested subdirectories.
    attr_reader :nesting_levels

    # The number of items allowed in any directory in a nested directory path.
    attr_reader :items_per_directory

    # An instance of FolderTree.
    attr_reader :tree

    def initialize(dir, nesting_levels: 2, items_per_directory: 1000)
      raise Errors::NoDirectoryError, dir: dir unless File.directory? dir

      @directory = dir
      @nesting_levels = nesting_levels
      @items_per_directory = items_per_directory
      @current_directory = File.join @directory, CURRENT_STORE_PATH

      @tree = FolderTree.empty directory,
                               levels: nesting_levels,
                               limit: items_per_directory

      link_target
    end

    # Returns the full path (_String_) to the current directory symlink.
    def current_directory
      File.expand_path @current_directory
    end

    # Returns the full path (_String_) to the current directory symlink.
    #
    # Creates new subdirectories and moves the current_directory symlink if the
    # #current_folder has reached the maximum #items_per_directory.
    def current_directory!
      available_folder = tree.available_folder
      unless available_folder == current_folder
        tree.new_branch_in available_folder
        link_target
      end

      current_directory
    end

    def current_folder
      tree.terminal
    end

    def current_path
      current_folder.path
    end

    def store(file)
      path = File.join current_directory!, File.basename(file)

      File.open(path, 'wb') { |f| f.write(File.new(file).read) }
      path
    end

    private

    # Changes the @current_directory symlink to +dir+
    def link_target
      FileUtils.ln_s File.expand_path(current_path), current_directory
    end
  end
end
