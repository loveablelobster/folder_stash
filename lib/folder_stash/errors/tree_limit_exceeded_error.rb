# frozen_string_literal: true

module FolderStash
  module Errors
    class TreeLimitExceededError < StandardError
      attr_reader :subdirs

      attr_reader :subdir_limit

      attr_reader :total

      def initialize(msg = nil, tree: nil)
        @subdirs = tree.path_length
        @subdir_limit = tree.limit
        @total = tree.path_length.times.inject(tree.limit) { |i| i * tree.limit }
        msg ||= "The storage tree has reached the limit of allowed items:"\
                " #{subdir_limit} items in #{subdirs} subdirectories"\
                " (#{total} allowd items in total)."
        super msg
      end
    end
  end
end
