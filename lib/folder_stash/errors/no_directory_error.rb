# frozen_string_literal: true

module FolderStash
  module Errors
    class NoDirectoryError < StandardError
      attr_reader :dir

      def initialize(msg = nil, dir: nil)
        @dir = dir
        msg ||= "The directory #{dir} does not exist or is not a directory"
        super msg
      end
    end
  end
end
