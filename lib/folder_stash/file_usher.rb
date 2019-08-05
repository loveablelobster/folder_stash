# frozen_string_literal: true

module FolderStash
  class FileUsher
    CURRENT_STORE_PATH = '.current_store_path'

    # The directory
    attr_reader :directory

    # The number of nested subdirectories
    attr_reader :nesting_levels

    #
    attr_reader :items_per_directory

    def initialize(dir, nesting_levels: 2, items_per_directory: 1000)
      raise Errors::NoDirectoryError, dir: dir unless File.directory? dir

      @directory = dir
      @current_directory = File.join @directory, CURRENT_STORE_PATH

      @current_folder = Folder.new @current_directory,
                                   limit: items_per_directory

      @nesting_levels = nesting_levels
      @items_per_directory = items_per_directory
      link_current_dir
    end

    def available?(dir = nil)
      Folder.new(dir, limit: items_per_directory).available?
    end

    def current_directory
      File.expand_path @current_directory
    end

    # Creates symlink to the directory where files will be stored until full.
    # this link should move from nested folder to nested folder
    def link_current_dir
      link_target make_nest(nesting_levels) unless File.exist? current_directory
    end

    def store(file); end

    private

    def storage_dir
      tree = FolderTree.new(@current_directory, directory, items_per_directory)
      available_parent = tree.available_folder
      raise 'out of storage' unless available_parent

      return if available_parent.path == current_directory

      tree.new_branch_in available_parent
      link_target tree.terminal.path
    end

    def current_folder_link
      File.join directory, 'current folder'
    end

    # Changes the @current_directory symlink to +dir+
    def link_target(dir)
      FileUtils.ln_s File.expand_path(dir), current_directory
    end

    # FIXME: use SecureRandom.hex(8)
    # FIXME: try to make an empty tree!
    def make_nest(levels)
      next_c_dir_path = levels.times.inject(@directory) do |dir|
        dir = File.join(dir, SecureRandom.uuid)
      end
      FileUtils.mkdir_p next_c_dir_path
      next_c_dir_path
    end
  end
end
