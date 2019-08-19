# frozen_string_literal: true

module FolderStash
  # A FolderTree represents a nested directory path.
  class FolderTree
    # An array with instances of Folder, one for each directory in a nested
    # directory path from the #root to the #terminal.
    attr_accessor :folders

    # The maximum number of itmes that may be stored in any folder in #folders.
    attr_reader :folder_limit

    # The number of items (directories) in a nested directory path, from the
    # #root (base directory) to the #terminal.
    attr_reader :path_length

    attr_reader :tree_limit

    # Returns a new instance.
    #
    # ===== Arguments
    #
    # * +folders+ (String) - Array of Folder instances.
    # * +levels+ (Integer) - Number of nested subdirectories in a path.
    # * +limit+ (Integer) - Number of items allowed in any folder in the
    #   tree's directory path.
    def initialize(folders, levels, limit)
      @folders = folders
      @path_length = levels ? levels + 1 : nil
      @folder_limit = limit
      @tree_limit = folder_limit ? folder_limit**(path_length) : nil
    end

    def self.empty(root, levels:, limit:)
      folders = [Folder.new(root)]
      tree = new(folders, levels, limit)
      tree.new_branch_in tree.root, levels
      tree
    end

    def self.for_path(path, root:, limit:)
      path_items = path_segment path, root
      folders = Folder.folders_for_path_segment root, path_items
      new folders, path_items.count, limit
    end

    def self.path_segment(terminal, root)
      File.expand_path(terminal).split('/') - File.expand_path(root).split('/')
    end

    # Returns the number of folder in the nested path currently available.
    def actual_path_length
      folders.count
    end

    # Returns the next available folder, searching upstream from the terminal
    # folder to the #root.
    #
    # Returns #root if root is the only folder.
    def available_folder
      return root if flat?

      folders.reverse.find { |folder| folder.count < folder_limit }
    end

    def branch_path
      folders.map(&:basename)
    end

    def flat?
      actual_path_length == 1 && path_length.nil?
    end

    # Returns the number of levels of folders nested in +folder+.
    def levels_below(folder)
      return if flat?

      subdirectories - folders.index(folder)
    end

    # The nesting depth (Integer) of subdirectories in the base directory.
    def subdirectories
      path_length - 1
    end

    # Creates a new branch of folders in +folder+ and updates #folders to the
    # new branch.
    #
    # Returns an array with the full path for the terminal folder in the branch
    # created.
    def new_branch_in(folder, levels = nil)
      return if flat?

      raise Errors::BranchError, dir: folder.path if folder == terminal

      raise TreeLimitExceededError, tree: self if folder.count >= folder_limit

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
    #
    # Returns +nil+ if the tree has not been fully initialized with a branch.
    def terminal
      return root if flat?

      return if actual_path_length < path_length

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
      Folder.new File.join(path, name)
    end

    # Returns an array of new Folder instances.
    def new_paths_in(folder, count)
      first_node = ensure_unique_node(folder.path, SecureRandom.hex(8))
      remainder = count - 1
      remainder.times.inject([first_node]) do |nodes|
        path = File.join nodes.last.path, SecureRandom.hex(8)
        nodes << Folder.new(path)
      end
    end
  end
end
