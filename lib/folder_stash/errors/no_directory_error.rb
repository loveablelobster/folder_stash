# frozen_string_literal: true

module FolderStash
  module Errors
    # Error that is raised if a directory does not exist.
    class NoDirectoryError < StandardError
      # Path for the directory that does not exist.
      attr_reader :dir

      def initialize(msg = nil, dir: nil)
        @dir = dir
        msg ||= "The directory #{dir} does not exist or is not a directory"
        super msg
      end
    end
  end
end
