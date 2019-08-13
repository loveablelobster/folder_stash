# frozen_string_literal: true

module FolderStash
  module Errors
    # Error that is raises when attempting to create a branch in a folder that
    # can not be branched (typically the terminal).
    class BranchError < StandardError
      # Directory for the folder where the branch was attempted.
      attr_reader :dir

      def initialize(msg = nil, dir: nil)
        @dir = dir
        msg ||= "Can not branch in #{dir} because it is a tree terminal."
        super msg
      end
    end
  end
end
