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

    # Returns a new instance.
    #
    # ===== Arguments
    #
    # * +dir+ (_String_) - path for the #directory.
    #
    # ===== Options
    #
    # * <tt>nesting_levels</tt> - the number of subdirectories below #directory
    #   in the path of files that are stored (_default_: +2+).
    # * <tt>items_per_directory</tt> - the maximum number of items allowed per
    #   directory (_default_: +10000+).
    #
    def initialize(dir, nesting_levels: 2, items_per_directory: 10000)
      raise Errors::NoDirectoryError, dir: dir unless File.directory? dir

      @directory = dir
      @items_per_directory = items_per_directory
      @current_directory = File.join @directory, CURRENT_STORE_PATH

      if File.exist? current_directory
        @tree = FolderTree.for_path File.readlink(current_directory),
                                    root: directory, limit: items_per_directory
      else
        @tree = FolderTree.empty directory,
                                 levels: nesting_levels,
                                 limit: items_per_directory
        link_target
      end
      @nesting_levels = tree.path_length
    end

    # Returns the full path (_String_) to the current directory symlink.
    def current_directory
      File.expand_path @current_directory
    end

    def current_folder
      tree.terminal
    end

    def current_path
      current_folder.path
    end

    def store(file)
      update_link unless current_folder.available?
      path = File.join current_directory!, File.basename(file)
      File.open(path, 'wb') { |f| f.write(File.new(file).read) }
      path
    end

    private

    def init_existing
      return unless File.exist? current_directory

      FolderTree.for_path File.readlink(current_directory),
                          root: directory, limit: items_per_directory
    end

    def init_new(levels)
      tree = FolderTree.empty directory, levels: levels,
                                 limit: items_per_directory
      link_target
      tree
    end

    # Changes the @current_directory symlink to +dir+
    def link_target
      FileUtils.ln_s File.expand_path(current_path), current_directory
    end

    def update_link
      tree.new_branch_in tree.available_folder
      link_target
    end
  end
end
