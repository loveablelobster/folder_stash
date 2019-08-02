# frozen_string_literal: true

module FolderStash
  # Notes:
  # - #current_dir is _always_ at deepest nesting_levels level
  # - if #current_dir has reached #limit?
  #   - check if parent of #current_dir has reached #limt?
  #     - if not, make new folder in parent
  #     - if yes, has parent of parent reached #limit?
  class FileUsher
    CURRENT_STORE_PATH = '.current_store_path'

    # The directory
    attr_reader :directory

    # The number of nested subdirectories
    attr_reader :nesting_levels

    #
    attr_reader :items_per_directory

    def initialize(dir, nesting_levels: 2, items_per_directory: 1000)
      raise NoDirectoryError, dir: dir unless File.directory? dir

      @directory = dir
      @current_directory = File.join @directory, CURRENT_STORE_PATH
      @nesting_levels = nesting_levels
      @items_per_directory = items_per_directory
      link_current_dir
    end

    def available?(dir = nil)
      entries(dir).count < @items_per_directory
    end

    def current_directory
      File.expand_path @current_directory
    end

    def limit?(dir = nil)
      entries(dir).count >= @items_per_directory
    end

    # Creates symlink to the directory where files will be stored until full.
    # this link should move from nested folder to nested folder
    def link_current_dir
      link_target make_nest(nesting_levels) unless File.exist? current_directory
    end

    def store(file); end

    private

    def storage_dir
      return if available?

      # Path (String) to an available directory
      available_parent = nesting_path.reverse.find { |dir| available?(dir) }

      if available_parent
        idx = nesting_path.index(available_parent)
        levels = nesting_path[idx..-1].count - 1
      else
        levels = nesting_path.count - 1
      end

      link_target make_nest(levels, available_parent)
    end

    def current_folder_link
      File.join directory, 'current folder'
    end

    # Returns all files and folders in +dir+ or @current_directory except hidden
    # files.
    #
    # To get entries of parent: <tt>entries('..')</tt>
    # To get entries of grandparent: <tt>entries('../..')</tt>
    def entries(dir = nil)
      dir ||= @current_directory
      Dir.children(dir).reject { |entry| entry.start_with? '.' }
    end

    # Changes the @current_directory symlink to +dir+
    def link_target(dir)
      FileUtils.ln_s File.expand_path(dir), current_directory
    end

    def make_nest(levels, root = nil)
      root ||= @directory
      next_c_dir_path = levels.times.inject(root) do |dir|
        dir = File.join(dir, SecureRandom.uuid)
      end
      FileUtils.mkdir_p next_c_dir_path
      next_c_dir_path
    end

    def nesting_path
      path = File.expand_path(@current_directory).split('/')
      root_path = File.expand_path(directory).split('/')
      path - root_path
    end
  end
end
