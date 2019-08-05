# frozen_string_literal: true

module FolderStash
  # A FolderTree represents a nested directory path.
  class FolderTree
    # An array with instances of Folder, one for each directory in a nested
    # directory path from the #root to the #terminal.
    attr_reader :folders

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
    def initialize(folder, root_dir, limit)
      path_items = (folder.split('/') - root_dir.split('/'))
      directories = path_items.inject([root_dir]) do |paths, dir|
        paths << File.join(paths.last, dir)
      end
      @folders = directories.map { |path| Folder.new(path, limit) }
      @limit = limit
      @path_length = path_items.count
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
    def new_branch_in(folder)
      raise Errors::BranchError, dir: folder.path if folder == terminal

      new_branch = new_paths_in folder
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

    # Returns an array of new Folder instances.
    def new_paths_in(folder)
      first_node = ensure_unique_node(folder.path, SecureRandom.hex(8))
      remainder = levels_below(folder) - 1
      remainder.times.inject([first_node]) do |nodes|
        path = File.join nodes.last.path, SecureRandom.hex(8)
        nodes << Folder.new(path, limit)
      end
    end
  end
end
