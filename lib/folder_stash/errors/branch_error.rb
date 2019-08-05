# frozen_string_literal: true

module FolderStash
  module Errors
    class BranchError < StandardError
      attr_reader :dir

      def initialize(msg = nil, dir: nil)
        @dir = dir
        msg ||= "Can not branch in #{dir} because it is a tree terminal."
        super msg
      end
    end
  end
end
