# frozen_string_literal: true

module FolderStash
  # A Folder represents a directory in the filesystem.
  class Folder
    # Basename for the folder.
    attr_reader :basename

    # Absolute path for the folder.
    attr_reader :path

    # Returns a new instance.
    #
    # ===== Arguments
    #
    # * +path+ (String) - path to the directory for the folder.
    def initialize(path)
      @path = File.expand_path path
      @basename = File.basename path
    end

    def self.folders_for_path_segment(root, segment)
      root_folder = Folder.new root
      segment.inject([root_folder]) do |dirs, dir|
        path = File.join dirs.last.path, dir
        dirs << Folder.new(path)
      end
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
