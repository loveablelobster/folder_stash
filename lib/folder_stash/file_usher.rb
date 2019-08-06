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
    attr_reader :folder_limit

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
    # * <tt>folder_limit</tt> - the maximum number of items allowed per
    #   directory (_default_: +10000+).
    #
    def initialize(dir, nesting_levels: 2, folder_limit: 10_000)
      raise Errors::NoDirectoryError, dir: dir unless File.directory? dir

      @directory = dir
      @folder_limit = folder_limit
      @current_directory = File.join @directory, CURRENT_STORE_PATH
      @tree = init_existing || init_new(nesting_levels)
      @nesting_levels = tree.path_length
      link_target
    end

    # Returns the full path (_String_) to the current directory symlink.
    def current_directory
      File.expand_path @current_directory
    end

    # Returns a Folder that is currently the FolderTree#terminal.
    def current_folder
      tree.terminal
    end

    # Returns the full directory path for #current_folder
    def current_path
      current_folder.path
    end

    # Returns the directory path the #current_directory symlink points to.
    def linked_path
      File.readlink current_directory
    end

    # Copies +file+ to the #linked_path.
    def store(file)
      update_link unless current_folder.available?
      path = File.join current_directory, File.basename(file)
      File.open(path, 'wb') { |f| f.write(File.new(file).read) }
      path
    end

    private

    # Returns +true+ if the current directory symlink exists in #directory.
    def current_directory?
      File.exist? current_directory
    end

    # Creates the folder #tree in an existing directory with #current_directory
    # symlink.
    def init_existing
      return unless current_directory?

      FolderTree.for_path linked_path, root: directory, limit: folder_limit
    end

    # Creates the folder #tree for a new direcrory without #current_directory
    # symlink.
    def init_new(levels)
      FolderTree.empty directory, levels: levels, limit: folder_limit
    end

    # Creates the current_directory symlink, pointing to the #current_path.
    def link_target
      return if current_directory? && linked_path == current_path

      FileUtils.ln_s File.expand_path(current_path), current_directory
    end

    # Creates new subdirectories points the #current_directory symlink to the
    # new #current_folder.
    def update_link
      tree.new_branch_in tree.available_folder
      link_target
    end
  end
end
