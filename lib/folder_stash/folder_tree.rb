# frozen_string_literal: true

module FolderStash
  # A FolderTree represents a nested directory path.
  class FolderTree
    # An array with instances of Folder, one for each directory in a nested
    # directory path from the #root to the #terminal.
    attr_accessor :folders

    # The maximum number of itmes that may be stored in any folder in #folders.
    attr_reader :limit

    # The number of items (directories) in a nested directory path, from the
    # #root to the #terminal.
    attr_reader :path_length

    # Returns a new instance.
    #
    # ===== Arguments
    #
    # * +folder+ (String) - path for the terminal folder in a tree.
    # * <tt>root_dir</tt> (String) - path for the #root directory in a tree.
    # * +limit+ (Integer) - the number of items allowed in any folder in the
    #   tree's directory path.
    def initialize(root_dir, folders, levels, limit = nil)
      @folders = folders
      @path_length = levels
      @limit = limit
    end

    def self.empty(root, levels:, limit:)
      folders = [Folder.new(root, limit)]
      tree = self.new(root, folders, levels, limit)
      tree.new_branch_in tree.root, levels
    end

    def self.for_path(path, root:, limit:)
      path_items = (path.split('/') - root.split('/'))
      root_folder = Folder.new root, limit
      folders = path_items.inject([root_folder]) do |dirs, dir|
        path = File.join dirs.last.path, dir
        dirs << Folder.new(path, limit)
      end
      self.new root, folders, path_items.count, limit
    end

    # Returns the next available folder, searching upstream from the terminal
    # folder to the #root.
    def available_folder
      folders.reverse.find(&:available?)
    end

    # Returns the number (integer) of levels of folders nested in +folder+.
    def levels_below(folder)
      path_length - folders.index(folder)
    end

    # Creates a new branch of folders in +folder+ and updates #folders to the
    # new branch.
    #
    # Returns an array with the full path for the terminal folder in the branch
    # created.
    def new_branch_in(folder, levels = nil)
      raise Errors::BranchError, dir: folder.path if folder == terminal

      levels ||= levels_below folder
      new_branch = new_paths_in folder, levels
      @folders = folders[0..folders.index(folder)].concat new_branch
      folders.last.create!
    end

    # Returns the root folder.
    def root
      folders.first
    end

    # Returns the terminal (most deeply nested) folder.
    def terminal
      folders.last
    end

    private

    # If the file <tt>path/name</tt> exists, randomize the name until a new
    # random is found that does not exist.
    #
    # Returns the new unique path name.
    #
    # This only needs to be called for the first new directory to be created,
    # all others will be created in empty directories and therefroe always be
    # unique.
    def ensure_unique_node(path, name)
      name = SecureRandom.hex(8) while File.exist? File.join(path, name)
      Folder.new File.join(path, name), limit
    end

    # FIXME: This should be the default initializer
    def init_empty(levels = nil)
      return unless levels

      @path_length = levels
      new_branch_in(root_dir, levels)
    end

    # Returns an array of new Folder instances.
    def new_paths_in(folder, count)
      first_node = ensure_unique_node(folder.path, SecureRandom.hex(8))
      remainder = count - 1
      remainder.times.inject([first_node]) do |nodes|
        path = File.join nodes.last.path, SecureRandom.hex(8)
        nodes << Folder.new(path, limit)
      end
    end
  end
end
