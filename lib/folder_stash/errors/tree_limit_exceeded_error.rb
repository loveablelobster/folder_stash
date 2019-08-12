# frozen_string_literal: true

module FolderStash
  module Errors
    class TreeLimitExceededError < StandardError
      attr_reader :subdirs

      attr_reader :subdir_limit

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
