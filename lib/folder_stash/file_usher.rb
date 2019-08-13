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
    # * <tt>link_location</tt> - the directory where the #current_directory
    #   symlink is stored. When not specified, the symlink will be in #directory
    #
    # Setting <tt>nesting_levels</tt> to +nil+ will also set the
    # <tt>folder_limit</tt>. Conversely, setting <tt>folder_limit</tt> to +nil+
    # also set <tt>nesting_levels</tt> to +nil+
    def initialize(dir, **opts)
      raise Errors::NoDirectoryError, dir: dir unless File.directory? dir

      @options = { nesting_levels: 2, folder_limit: 10_000 }.update(opts)
      @directory = dir
      @current_directory = File.join @options.fetch(:link_location, directory),
                                     CURRENT_STORE_PATH

      @tree = init_existing || init_new(nesting_levels)
      link_target
    end

    # Copies +file+ to linked path.
    def copy(file, pathtype: :tree)
      path = store_path(file)
      File.open(path, 'wb') { |f| f.write(File.new(file).read) }
      file_path path, pathtype
    end

    # Returns the full path (_String_) to the current directory symlink.
    def current_directory
      File.expand_path @current_directory
    end

    # Returns the full directory path for #current_folder
    def current_path
      current_folder.path
    end

    # The number of items allowed in any directory in a nested directory path.
    #
    # Will be +nil+ if #nesting_levels is +nil+.
    def folder_limit
      return unless @options.fetch :nesting_levels

      @options.fetch :folder_limit
    end

    # Returns the directory path the #current_directory symlink points to.
    def linked_path
      File.readlink current_directory
    end

    # Moves +file+ to the #linked_path.
    def move(file, pathtype: :tree)
      path = store_path(file)
      FileUtils.mv File.expand_path(file), store_path(file)
      file_path path, pathtype
    end

    # The number of nested subdirectories.
    def nesting_levels
      return unless @options.fetch :folder_limit

      tree&.path_length || @options.fetch(:nesting_levels)
    end

    private

    # Returns the next available folder in #tree. Will raise OutOfStorageError
    # if none is available.
    def available_folder
      folder = tree.available_folder
      raise Errors::TreeLimitExceededError, tree: tree unless folder

      folder
    end

    # Returns +true+ if the current directory symlink exists in #directory.
    def current_directory?
      File.exist? current_directory
    end

    # Returns a Folder that is currently the FolderTree#terminal.
    def current_folder
      tree.terminal
    end

    # Returns the path for +path+ as +:absolute+, +:relative+, or only the
    # nested subdirectories in the +:tree+.
    def file_path(path, pathtype)
      treepath = tree.branch_path.append(File.basename(path))
      case pathtype
      when :absolute
        File.realpath path
      when :relative
        treepath[0] = directory
        treepath.join('/')
      when :tree
        treepath.join('/')
      end
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

    # Returns the next available path (_String_) for a file to be stored under.
    def store_path(file)
      update_link if folder_limit && current_folder.count >= folder_limit
      File.join current_directory, File.basename(file)
    end

    # Creates new subdirectories points the #current_directory symlink to the
    # new #current_folder.
    def update_link
      tree.new_branch_in available_folder
      FileUtils.rm current_directory
      link_target
    end
  end
end
