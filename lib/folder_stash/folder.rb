# frozen_string_literal: true

module FolderStash
  # A Folder represents a directory in the filesystem.
  class Folder
    # The directory for the folder.
    attr_reader :path

    # The number of items (excluding hidden files) that may be stored in the
    # folder's directory.
    attr_reader :limit

    # Returns a new instance.
    #
    # ===== Arguments
    #
    # * +path+ (String) - path to the directory for the folder.
    # * +limit+ (Integer) - the number of items allowed in any folder in the
    #   tree's directory path.
    def initialize(path, limit = nil)
      @path = File.expand_path path
      @limit = limit
    end

    # Returns +true+ if the #limit the nomber of entries in the folder is below
    # the limit and additional items may be stored.
    def available?
      count < limit
    end

    # Returns the number of visible files in the folder.
    def count
      entries.count
    end

    # Creates the directory path in the immediate parent.
    def create
      FileUtils.mkdir path unless exist?
    end

    # Creates the directory #path with all parents.
    def create!
      FileUtils.mkdir_p path unless exist?
    end

    # Returns +true+ if the directory #path exists.
    def exist?
      File.exist? path
    end

    # Returns +true+ if the number of entries in the folder has reached or
    # exceeds the limit.
    def limit?
      count >= limit
    end

    # Returns a list of entries (files or folders) in the folder.
    #
    # ===== Options
    #
    # * <tt>include_hidden</tt>
    #   * +true+ - list visible and hidden entries.
    #   * +false+ (_default_) - list only visible entries.
    def entries(include_hidden: false)
      children = Dir.children path
      return children if include_hidden == true

      children.reject { |entry| entry.start_with? '.' }
    end
  end
end
