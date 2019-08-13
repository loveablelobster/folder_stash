# frozen_string_literal: true

module FolderStash
  module Errors
    # Error that is raised when the number of items in a tree has exceeded the
    # maximum number allowed in a tree.
    class TreeLimitExceededError < StandardError
      # Number of subdirectories in a given path (branch) of the tree.
      attr_reader :subdirs

      # Number of items allowed in a subdirectory.
      attr_reader :subdir_limit

      # Total number of items allowed in a tree.
      attr_reader :tree_limit

      def initialize(msg = nil, tree: nil)
        @subdirs = tree.path_length
        @subdir_limit = tree.folder_limit
        @tree_limit = tree.tree_limit
        msg ||= 'The storage tree has reached the limit of allowed items:'\
                " #{subdir_limit} items in #{subdirs} subdirectories"\
                " (#{tree_limit} allowd items in total)."
        super msg
      end
    end
  end
end
